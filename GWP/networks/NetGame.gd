extends Node

signal sig_connection_success()
signal sig_connection_failed()
signal sig_server_disconnected()

# struct is same as ready_room_info
var game_room_info = null

var _rand_generator : RandomNumberGenerator = null

func _on_peer_connected(id):
	Debug.verbose("peer(%d) is connected." % id)
	# let server handle connections
	if not get_tree().is_network_server():
		return


func _on_peer_disconnected(id):
	Debug.verbose("peer(%d) is disconnected." % id)


func _on_connection_success():
	Debug.verbose("connect server successfully.")
	emit_signal("sig_connection_success")


func _on_connection_failed():
	Debug.error("connect server failed.")
	emit_signal("sig_connection_failed")


func _on_server_disconnected():
	Debug.warning("server is disconnected.")
	Debug.alert("server is disconnected.")
	emit_signal("sig_server_disconnected")
	SceneMgr.load_hall()


# client&server->server
master func _on_leave_game(id):
	Debug.verbose("recv game leave: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(id)]
	))
	if id == 1:
		emit_signal("sig_server_disconnected")
	else:
		pass


func leave_game():
	rpc_id(1, "_on_leave_game", get_tree().get_network_unique_id())
	get_tree().set_network_peer(null)
	SceneMgr.load_hall()


func set_rand_seed(game_seed):
	_rand_generator = RandomNumberGenerator.new()
	_rand_generator.seed = game_seed

func get_rand(from:int, to:int):
	return _rand_generator.randi_range(from, to)
