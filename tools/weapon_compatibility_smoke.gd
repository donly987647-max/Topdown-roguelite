extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_test_incompatible_parts_are_legal_with_power_penalty()
	_test_mara_reduces_incompatible_power_penalty()
	if failures.is_empty():
		print("WEAPON_COMPATIBILITY_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _test_incompatible_parts_are_legal_with_power_penalty() -> void:
	var build := _make_incompatible_build()
	var base_cost := build.base_power_cost()
	_expect(build.is_complete(), "test build must be complete")
	_expect(build.is_compatible(), "incompatible-tag parts must remain legal to assemble")
	_expect(not build.is_tag_compatible(), "mismatched tags must still be reported")
	_expect(build.incompatible_part_count() == 1, "exactly one test part should be incompatible")
	_expect(build.total_power_cost() > base_cost, "incompatible part must add power surcharge")
	var expected := base_cost + 10.0 * WeaponBuild.INCOMPATIBLE_POWER_SURCHARGE_RATE
	_expect(is_equal_approx(build.total_power_cost(), expected), "default incompatible surcharge must apply only to the mismatched part")

func _test_mara_reduces_incompatible_power_penalty() -> void:
	var build := _make_incompatible_build()
	var default_surcharge := build.incompatible_power_surcharge()
	build.compatibility_penalty_scale = CharacterAbilityRuntime.MARA_INCOMPATIBLE_POWER_PENALTY_SCALE
	_expect(build.incompatible_power_surcharge() < default_surcharge, "Mara penalty scale must reduce incompatible power surcharge")
	_expect(is_equal_approx(build.incompatible_power_surcharge(), default_surcharge * 0.5), "provisional Mara tuning should halve the incompatible surcharge")

func _make_incompatible_build() -> WeaponBuild:
	var frame := WeaponFrameDefinition.new()
	frame.id = &"test_frame"
	frame.compatibility_tags = PackedStringArray(["ballistic"])
	frame.max_power = 100.0
	frame.max_weight = 100.0
	frame.base_damage = 10.0
	frame.fire_interval = 0.2
	frame.magazine_size = 10
	frame.reload_time = 1.0
	frame.stability = 1.0

	var barrel := WeaponPartDefinition.new()
	barrel.id = &"mismatch_barrel"
	barrel.part_type = WeaponPartDefinition.PartType.BARREL
	barrel.compatible_tags = PackedStringArray(["energy"])
	barrel.power_cost = 10.0

	var magazine := WeaponPartDefinition.new()
	magazine.id = &"universal_mag"
	magazine.part_type = WeaponPartDefinition.PartType.MAGAZINE
	magazine.power_cost = 5.0

	var core := WeaponPartDefinition.new()
	core.id = &"universal_core"
	core.part_type = WeaponPartDefinition.PartType.CORE
	core.power_cost = 5.0

	var build := WeaponBuild.new()
	build.frame = frame
	build.barrel = barrel
	build.magazine = magazine
	build.core = core
	return build

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
