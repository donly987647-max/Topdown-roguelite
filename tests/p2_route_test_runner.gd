extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_room_data_contract()
	_test_eight_room_route_contract()
	_test_defensive_copies()
	_test_runtime_files()
	if failures.is_empty():
		print("[P2 ROUTE TEST] PASS")
		quit(0)
	else:
		for failure in failures:
			push_error("[P2 ROUTE TEST] %s" % failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_room_data_contract() -> void:
	var room := RouteRoomData.new()
	room.room_id = &"contract_room"
	room.stage_index = 3
	room.display_name = "CONTRACT ROOM"
	room.enemy_count = 4
	room.enemy_health_multiplier = 1.2
	room.enemy_damage_multiplier = 1.1
	_expect(room.validate_contract().is_empty(), "Valid route room must pass its data contract")
	room.enemy_count = 0
	_expect(not room.validate_contract().is_empty(), "Zero-enemy route room must fail its data contract")

func _test_eight_room_route_contract() -> void:
	var route := PrototypeRouteRun.new(424242)
	var first := route.start()
	_expect(first != null, "Route must provide a starting room")
	_expect(first.stage_index == 0, "Starting room must be stage zero")
	_expect(route.history.size() == 1, "Starting the route must record the first room")
	_expect(not route.is_complete(), "Fresh route must not be complete")

	var stage_two := route.get_next_options()
	_expect(stage_two.size() == 2, "Second stage must offer safe and danger choices")
	_expect(_has_path(stage_two, &"safe"), "Second stage safe route missing")
	_expect(_has_path(stage_two, &"danger"), "Second stage danger route missing")
	var before_invalid := route.history.size()
	_expect(route.choose_next(&"missing_room") == null, "Invalid room ID must be rejected")
	_expect(route.history.size() == before_invalid, "Invalid choice must not advance route history")

	var selected_ids := [
		&"crusher_bypass",
		&"coolant_gallery",
		&"sorting_core",
		&"overclocked_cell",
		&"supply_transfer",
		&"foreman_gate",
		&"gr01_antechamber"
	]
	for selected_id in selected_ids:
		var next_room := route.choose_next(selected_id)
		_expect(next_room != null, "Expected route choice missing: %s" % selected_id)
		if next_room != null:
			_expect(next_room.stage_index == route.history.size() - 1, "Route stage index must match visit order")

	_expect(route.history.size() == PrototypeRouteRun.TOTAL_ROOMS, "Route must contain exactly eight visited rooms")
	_expect(route.stage_index == 7, "Final route stage must be index seven")
	_expect(route.current_room.room_type == RouteRoomData.RoomType.BOSS_GATE, "Final room must be the prototype boss gate")
	_expect(route.is_complete(), "Eight visited rooms must complete the route")
	_expect(route.get_next_options().is_empty(), "Completed route must not expose additional rooms")
	var snapshot := route.get_progress_snapshot()
	_expect(int(snapshot.get("room_number", 0)) == 8, "Progress snapshot must report room eight")
	_expect(int(snapshot.get("total_rooms", 0)) == 8, "Progress snapshot total must remain eight")
	_expect((snapshot.get("visited_ids", PackedStringArray()) as PackedStringArray).size() == 8, "Progress snapshot must include all visited IDs")
	_expect(bool(snapshot.get("complete", false)), "Progress snapshot must report completion")

func _test_defensive_copies() -> void:
	var route := PrototypeRouteRun.new(17)
	var first := route.start()
	first.display_name = "MUTATED"
	_expect(route.current_room.display_name != "MUTATED", "Start room must be returned as a defensive copy")
	var options := route.get_next_options()
	options[0].enemy_count = 99
	var fresh_options := route.get_next_options()
	_expect(fresh_options[0].enemy_count != 99, "Route options must be returned as defensive copies")

func _test_runtime_files() -> void:
	for path in [
		"res://scripts/routes/route_room_data.gd",
		"res://scripts/routes/prototype_route_run.gd",
		"res://scripts/ui/route_choice_panel.gd",
		"res://scripts/ui/route_status_panel.gd",
		"res://scripts/world/test_room.gd",
		"res://scripts/main/main.gd"
	]:
		_expect(ResourceLoader.exists(path), "Required route runtime file missing: %s" % path)

func _has_path(options: Array[RouteRoomData], path_kind: StringName) -> bool:
	for option in options:
		if option.path_kind == path_kind:
			return true
	return false
