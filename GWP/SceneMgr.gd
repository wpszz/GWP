extends Node

var current_scene = null

var _loading_scene = null
var _next_scene = null
var _next_scene_callback = null

func load_scene(path:String, callback:FuncRef = null):
	if callback == null:
		callback = funcref(self, "_on_loading_done_default")
	call_deferred("_load_scene_deferred", path, callback)


func _on_loading_done_default(err):
	if err == OK:
		Loading.hide()
	else:
		pass


func _load_scene_deferred(path:String, callback:FuncRef):
	if not ResourceLoader.exists(path):
		Debug.warning("scene %s is not found." % path)
		callback.call_func(FAILED)
		return
	if _loading_scene != null:
		_next_scene = path
		_next_scene_callback = callback
		Debug.warning("scene %s is loading..." % _loading_scene)
		return

	_loading_scene = path
	Loading.show()

	if current_scene != null:
		current_scene.free()

	var res_loader = ResourceLoader.load_interactive(path)
	while true:
		yield(get_tree(), "idle_frame")
		var ret = res_loader.poll()
		if ret == ERR_FILE_EOF:
			break
		elif ret == OK:
			Loading.set_progress(float(res_loader.get_stage()) / res_loader.get_stage_count())
		else:
			Debug.error("scene %s load failed, error code: %d" % [path, ret])
			callback.call_func(FAILED)
			return

	var res = res_loader.get_resource()

	current_scene = res.instance()
	get_tree().get_root().add_child(current_scene)
	# Optionally, to make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)

	_loading_scene = null

	Loading.set_progress(1.0)
	yield(Loading, "sig_loading_done")

	if _next_scene != null:
		var tmp_scene = _next_scene
		var _tmp_callback = _next_scene_callback
		_next_scene = null
		_next_scene_callback = null
		load_scene(tmp_scene, _tmp_callback)

	callback.call_func(OK)


func load_hall():
	SceneMgr.load_scene("res://Hall.tscn")


func get_game_script(game_id):
	var script_path = "res://games/%s/%s.gd" % [game_id, game_id]
	if not ResourceLoader.exists(script_path, "GDScript"):
		Debug.warning("game script %s is not found." % game_id)
		return null
	var game_script = load(script_path)
	return game_script


func get_game_scene_path(game_id):
	return "res://games/%s/%s.tscn" % [game_id, game_id]
