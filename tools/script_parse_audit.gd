extends SceneTree

var _script_paths: Array[String] = []
var _failures: Array[String] = []

func _initialize() -> void:
	_collect_scripts("res://")
	_script_paths.sort()
	print("script_parse_audit: checking %d GDScript files" % _script_paths.size())
	for path in _script_paths:
		if path == "res://tools/script_parse_audit.gd":
			continue
		var resource: Resource = ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
		if resource == null or not (resource is GDScript):
			_failures.append(path + " (load failed)")
			continue
		var script: GDScript = resource as GDScript
		var error: Error = script.reload(true)
		if error != OK:
			_failures.append(path + " (reload error %d)" % int(error))
	if _failures.is_empty():
		print("script_parse_audit: PASS (%d files)" % _script_paths.size())
		quit(0)
		return
	for failure in _failures:
		push_error("script_parse_audit: " + failure)
	print("script_parse_audit: FAIL (%d/%d)" % [_failures.size(), _script_paths.size()])
	quit(1)

func _collect_scripts(root: String) -> void:
	var dir := DirAccess.open(root)
	if dir == null:
		_failures.append(root + " (directory open failed)")
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		var path := root.path_join(name)
		if dir.current_is_dir():
			_collect_scripts(path)
		elif name.ends_with(".gd"):
			_script_paths.append(path)
	dir.list_dir_end()
