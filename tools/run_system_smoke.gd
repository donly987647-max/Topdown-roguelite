extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var generator := RunGraphGenerator.new()
	var graph := generator.generate(12345)
	var validation := generator.validate(graph)
	_assert(bool(validation.get("valid", false)), "generated graph must be valid")
	_assert(graph.next_nodes(graph.start_id).size() >= 1, "start must have at least one choice")
	_assert(graph.has_path(graph.start_id, graph.boss_id), "boss must be reachable")

	var selector := RewardSelector.new()
	for i in range(5):
		selector.add_offer(RewardOffer.new(StringName("reward_%d" % i), &"module", &"common", {"index": i}, 1.0))
	var choices := selector.generate_choices()
	_assert(choices.size() == 3, "reward selector must return three choices when pool allows")
	var ids: Dictionary = {}
	for offer in choices:
		_assert(not ids.has(offer.id), "reward choices must be unique")
		ids[offer.id] = true
	selector.claim(choices[0])
	_assert(selector.claim_count(choices[0].id) == 1, "claim history must increment")

	var passive := PassiveModuleDefinition.new()
	passive.id = &"test_passive"
	passive.stat_modifiers = {"damage_mult": {"op": "mul", "value": 1.2}}
	var passive_runtime := PassiveModuleRuntime.new()
	passive_runtime.add_module(passive)
	_assert(is_equal_approx(passive_runtime.modify_value(&"damage", 10.0), 12.0), "damage multiplier must affect the mapped base value")
	_assert(is_equal_approx(passive_runtime.stat(&"damage_mult", 1.0), 1.2), "passive stat aggregation must work")
	passive_runtime.free()

	if failures.is_empty():
		print("run_system_smoke: PASS")
		quit(0)
		return
	for failure in failures:
		push_error("run_system_smoke: " + failure)
	print("run_system_smoke: FAIL (%d)" % failures.size())
	quit(1)

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
