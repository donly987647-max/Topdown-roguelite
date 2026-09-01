extends SceneTree

const WeaponAssemblyScript = preload("res://scripts/combat/weapon_assembly.gd")

var failures: Array[String] = []

func _init() -> void:
    var assembly = WeaponAssemblyScript.new()
    var frames: Array = assembly.catalog.get("frames", [])
    var barrels: Array = assembly.catalog.get("barrels", [])
    var magazines: Array = assembly.catalog.get("magazines", [])
    var cores: Array = assembly.catalog.get("cores", [])

    _check(frames.size() >= 3, "expected at least 3 frames")
    _check(barrels.size() >= 4, "expected at least 4 barrels")
    _check(magazines.size() >= 4, "expected at least 4 magazines")
    _check(cores.size() >= 4, "expected at least 4 cores")

    var combinations := 0
    for f in frames.size():
        for b in barrels.size():
            for m in magazines.size():
                for c in cores.size():
                    assembly.selections["frame"] = f
                    assembly.selections["barrel"] = b
                    assembly.selections["magazine"] = m
                    assembly.selections["core"] = c
                    var resolved: Dictionary = assembly.resolve()
                    combinations += 1
                    _check(float(resolved.get("damage", 0.0)) > 0.0, "damage must stay positive")
                    _check(float(resolved.get("fire_interval", 0.0)) > 0.0, "fire interval must stay positive")
                    _check(int(resolved.get("magazine_size", 0)) > 0, "magazine size must stay positive")
                    _check(float(resolved.get("reload_time", 0.0)) > 0.0, "reload time must stay positive")
                    _check(float(resolved.get("movement_multiplier", 0.0)) >= 0.70, "movement penalty exceeded floor")
                    _check(float(resolved.get("dodge_distance_multiplier", 0.0)) >= 0.72, "dodge penalty exceeded floor")

    assembly.selections = {"frame": 0, "barrel": 0, "magazine": 0, "core": 0}
    var precision := assembly.resolve()
    _check(float(precision.get("projectile_speed", 0.0)) > float(frames[0].get("projectile_speed", 0.0)), "precision barrel must increase projectile speed")

    assembly.selections["barrel"] = 1
    var scatter := assembly.resolve()
    _check(int(scatter.get("projectile_count", 0)) == 3, "scatter barrel must add two projectiles")

    assembly.selections["barrel"] = 2
    var piercing := assembly.resolve()
    _check(int(piercing.get("pierce_count", 0)) == 2, "piercing barrel must add two pierces")

    assembly.selections["barrel"] = 3
    var ricochet := assembly.resolve()
    _check(int(ricochet.get("ricochet_count", 0)) == 2, "ricochet barrel must add two wall bounces")

    assembly.selections = {"frame": 0, "barrel": 0, "magazine": 0, "core": 0}
    var large := assembly.resolve()
    _check(int(large.get("magazine_size", 0)) > int(frames[0].get("magazine_size", 0)), "large magazine must increase capacity")

    assembly.selections["magazine"] = 1
    var light := assembly.resolve()
    _check(float(light.get("reload_time", 99.0)) < float(frames[0].get("reload_time", 0.0)), "light magazine must reduce reload time")

    assembly.selections["magazine"] = 2
    var explosive := assembly.resolve()
    _check(bool(explosive.get("explosive_last_round", false)), "explosive magazine flag missing")

    assembly.selections["magazine"] = 3
    var reverse := assembly.resolve()
    _check(bool(reverse.get("reverse_magazine", false)), "reverse magazine flag missing")

    var expected_effects := ["fire", "frost", "electric", "corrosion"]
    for c in expected_effects.size():
        assembly.selections["core"] = c
        var core_build := assembly.resolve()
        _check(String(core_build.get("effect", "")) == expected_effects[c], "core effect mismatch at index %d" % c)

    if failures.is_empty():
        print("WEAPON_ASSEMBLY_AUDIT_OK combinations=%d" % combinations)
        quit(0)
    else:
        for message in failures:
            push_error("WEAPON_ASSEMBLY_AUDIT: " + message)
        quit(1)

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
