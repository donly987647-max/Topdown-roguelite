extends SceneTree

var _failures: Array[String] = []

func _initialize() -> void:
	_test_backpack_grid_contract()
	_test_directional_power_link()
	_test_weapon_payload_contract()
	if _failures.is_empty():
		print("GDD runtime smoke: PASS")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	print("GDD runtime smoke: FAIL (%d)" % _failures.size())
	quit(1)

func _test_backpack_grid_contract() -> void:
	var grid := BackpackGrid.new()
	_assert(grid.place(&"legacy", [Vector2i.ZERO], Vector2i(0, 0)), "legacy BackpackGrid.place should work")
	_assert(grid.item_at(Vector2i.ZERO) == &"legacy", "occupancy lookup should return placed item")
	_assert(grid.remove(&"legacy"), "legacy placement should be removable")

func _test_directional_power_link() -> void:
	var source := BackpackItemDefinition.new()
	source.id = &"battery"
	source.cells = PackedVector2Array([Vector2.ZERO])
	source.power_supply = 10.0
	source.connector_types = {"right": "power_out"}
	var consumer := BackpackItemDefinition.new()
	consumer.id = &"module"
	consumer.cells = PackedVector2Array([Vector2.ZERO])
	consumer.power_draw = 6.0
	consumer.requires_power = true
	consumer.connector_types = {"left": "power_in"}
	var grid := BackpackGrid.new()
	_assert(grid.place_item(source, Vector2i(1, 1)), "power source should place")
	_assert(grid.place_item(consumer, Vector2i(2, 1)), "power consumer should place")
	var result := BackpackSynergyResolver.new().resolve(grid)
	_assert(result["connector_links"].size() == 1, "facing power terminals should create exactly one link")
	_assert(bool(result["powered_items"].get(&"module", false)), "consumer inside powered network should be powered")
	_assert(absf(float(result["power_supply"]) - 10.0) < 0.001, "power supply total should be 10")
	_assert(absf(float(result["power_draw"]) - 6.0) < 0.001, "power draw total should be 6")

func _test_weapon_payload_contract() -> void:
	var frame := WeaponFrameDefinition.new()
	frame.id = &"service_pistol"
	var barrel := WeaponPartDefinition.new()
	barrel.id = &"piercing_barrel"
	barrel.part_type = WeaponPartDefinition.PartType.BARREL
	var magazine := WeaponPartDefinition.new()
	magazine.id = &"cross_mag"
	magazine.part_type = WeaponPartDefinition.PartType.MAGAZINE
	var core := WeaponPartDefinition.new()
	core.id = &"electric_core"
	core.part_type = WeaponPartDefinition.PartType.CORE
	core.effect_ids = PackedStringArray(["shock"])
	var build := WeaponBuild.new()
	build.frame = frame
	build.barrel = barrel
	build.magazine = magazine
	build.core = core
	var payload := WeaponEffectResolver.shot_payload(build, build.computed_stats())
	_assert(int(payload["pierce"]) >= 2, "piercing barrel should add two pierces")
	_assert(bool(payload["cross_mag"]), "cross magazine payload flag should be present")
	_assert(StringName(payload["status_id"]) == &"shock", "electric core should resolve shock payload")

func _assert(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
