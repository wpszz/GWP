extends Node

signal sig_connection_success()
signal sig_connection_failed()
signal sig_server_disconnected()

signal sig_ready_room_is_full()
signal sig_ready_room_is_busy()
signal sig_ready_room_update()
signal sig_ready_room_kicked()
signal sig_ready_room_chat(what)

# constants
const DEFAULT_HOST = "127.0.0.1"
const DEFAULT_PORT = 4811
const DEFAULT_ROOM_NAME = "free room"
const DEFAULT_GAME_ID = "TankWar"
const DEFAULT_PLAYER_NAME = "player"
const DEFAULT_START_GAME_COUNTDOWN = 5

enum {
	ROOM_READY,
	ROOM_COUNTDOWN,
	ROOM_LOADING,
	ROOM_START,
}

enum {
	CHAT_NORMAL,
	CHAT_SYSTEM,
}

# data of local host
var local_host_config = {
	host = DEFAULT_HOST,
	port = DEFAULT_PORT,
	room_name = DEFAULT_ROOM_NAME,
	game_id = DEFAULT_GAME_ID,
	player_name = DEFAULT_PLAYER_NAME,
}

# data of ready room
var ready_room_info = null

func _on_peer_connected(id):
	Debug.verbose("peer(%d) is connected." % id)
	# let server handle connections
	if not get_tree().is_network_server():
		return
	rpc_id(id, "_on_pull_client_info")


func _on_peer_disconnected(id):
	Debug.verbose("peer(%d) is disconnected." % id)
	# let server handle disconnections
	if not get_tree().is_network_server():
		return
	_on_leave_ready_room(id)


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

# server->client
remote func _on_pull_client_info():
	var seat_info = {
		player_id = get_tree().get_network_unique_id(),
		player_name = local_host_config.player_name,
		ready = false,
		load_ok = false,
	}
	rpc_id(1, "_on_push_client_info", seat_info)

# client->server
remote func _on_push_client_info(seat_info):
	#print("seat_info", str(seat_info))
	var id = seat_info.player_id #get_tree().get_rpc_sender_id()
	if ready_room_info.room_status != ROOM_READY:
		rpc_id(id, "_on_ready_room_is_busy", ready_room_info.room_status)
		get_tree().get_network_peer().disconnect_peer(id, false)
		return
	if not ProtoHall.Room.try_insert_player(ready_room_info, seat_info):
		# room is full or unique id conflict(hash collision)？
		rpc_id(id, "_on_ready_room_is_full")
		get_tree().get_network_peer().disconnect_peer(id, false)
		return
	rpc("_on_ready_room_update", ready_room_info)
	send_chat("%s join" % seat_info.player_name, CHAT_SYSTEM)

# server->client
remote func _on_ready_room_is_full():
	get_tree().set_network_peer(null)
	Debug.alert("the room is full.")
	emit_signal("sig_ready_room_is_full")

# server->client
remote func _on_ready_room_is_busy(status):
	get_tree().set_network_peer(null)
	Debug.alert("the room is busy, status is %s." % status)
	emit_signal("sig_ready_room_is_busy")

# server->client
remote func _on_ready_room_kicked():
	get_tree().set_network_peer(null)
	Debug.alert("you are kicked from ready room.")
	emit_signal("sig_ready_room_kicked")

# server->client&server
remotesync func _on_ready_room_update(room_info):
	Debug.verbose("recv room update: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(room_info)]
	))
	var id = get_tree().get_network_unique_id()
	if ProtoHall.Room.try_get_player(room_info, id) != null:
		ready_room_info = room_info
		emit_signal("sig_ready_room_update")
	else:
		Debug.warning("peer(%d) are not in the room" % id)

# client&server->server
master func _on_change_seat_info(seat_to):
	Debug.verbose("recv room change seat: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(seat_to)]
	))
	var id = get_tree().get_rpc_sender_id()
	var old_seat_info = ProtoHall.Room.try_get_player(ready_room_info, id)
	if old_seat_info != null:
		var to_seat_info = ProtoHall.Room.try_get_seat(ready_room_info, seat_to.camp_idx, seat_to.seat_idx)
		if to_seat_info != null and (to_seat_info.player_id == id or ProtoHall.Seat.is_open(to_seat_info)):
			if to_seat_info.player_id == id:
				to_seat_info.ready = seat_to.ready
			else:
				to_seat_info.player_id = old_seat_info.player_id
				to_seat_info.player_name = old_seat_info.player_name
				to_seat_info.ready = seat_to.ready
				ProtoHall.Seat.open(old_seat_info)
			rpc("_on_ready_room_update", ready_room_info)
	else:
		Debug.warning("peer(%d) are not in the room" % id)

# client&server->server
master func _on_leave_ready_room(id):
	Debug.verbose("recv room leave: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(id)]
	))
	if id == 1:
		emit_signal("sig_server_disconnected")
	else:
		var seat_info = ProtoHall.Room.try_get_player(ready_room_info, id)
		var player_name = seat_info.player_name if seat_info != null else ""
		if ProtoHall.Room.try_remove_player(ready_room_info, id):
			rpc("_on_ready_room_update", ready_room_info)
			send_chat("%s leave" % player_name, CHAT_SYSTEM)
		else:
			Debug.warning("peer(%d) are not in the room" % id)

# client&server->client&server
remotesync func _on_ready_room_chat(chat):
	Debug.verbose("recv room chat: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(chat)]
	))
	var receiver = ProtoHall.Room.try_get_player(ready_room_info, get_tree().get_network_unique_id())
	if receiver == null:
		return
	var sender = ProtoHall.Room.try_get_player(ready_room_info, get_tree().get_rpc_sender_id())
	if sender == null:
		return
	if chat.type == CHAT_SYSTEM:
		emit_signal("sig_ready_room_chat", "system: %s" % chat.what)
	else:
		var who = "(You)" if sender.player_id == receiver.player_id else ""
		emit_signal("sig_ready_room_chat", "%s%s: %s" % [sender.player_name, who, chat.what])

# server->client&server
remotesync func _on_loading_game(game_room_info):
	Debug.verbose("recv loading: sender={0} receiver={1} data={2}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id(), str(game_room_info)]
	))
	var id = get_tree().get_network_unique_id()
	if ProtoHall.Room.try_get_player(game_room_info, id) != null:
		ready_room_info.room_status = ROOM_LOADING
		NetGame.game_room_info = game_room_info
		NetGame.set_rand_seed(game_room_info.game_seed)
		var game_scene_path = SceneMgr.get_game_scene_path(game_room_info.game_id)
		SceneMgr.load_scene(game_scene_path, funcref(self, "_on_loading_game_done"))
	else:
		Debug.warning("peer(%d) are not in the room" % id)	

# client&server->server
master func _on_loading_game_ok():
	Debug.verbose("recv loading ok: sender={0} receiver={1}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id()]
	))
	var id = get_tree().get_rpc_sender_id()
	var seat_info = ProtoHall.Room.try_get_player(NetGame.game_room_info, id)
	if seat_info != null:
		seat_info.load_ok = true
		if ProtoHall.Room.is_all_load_ok(NetGame.game_room_info):
			rpc("_on_game_start")
	else:
		Debug.warning("peer(%d) are not in the room" % id)	

# server->client&server
remotesync func _on_game_start():
	Debug.verbose("recv game start: sender={0} receiver={1}".format(
		[get_tree().get_rpc_sender_id(), get_tree().get_network_unique_id()]
	))

	ready_room_info.room_status = ROOM_START
	NetCenter.bind_game_net()
	Loading.hide()
	get_tree().set_pause(false)


func _on_loading_game_done(err):
	if err == OK:
		rpc_id(1, "_on_loading_game_ok")
	else:
		#rpc("_on_loading_game_failed")
		# just leave the room and go back to the hall
		leave_room()
		SceneMgr.load_hall()


func host_room():
	# init room data
	var game_id = local_host_config.game_id
	var game_script = SceneMgr.get_game_script(game_id)
	if game_script == null:
		Debug.alert("game %s is not found." % game_id, "error")
		return false
	var map_about = game_script.get_about()
	ready_room_info = {
		room_name = local_host_config.room_name,
		game_id = game_id,
		camps = [],
		room_status = ROOM_READY,
	}
	for camp_config in map_about.camp_configs:
		var camp_info = {
			camp_name = camp_config.camp_name,
			seats = [],
		}
		for _i in camp_config.max_players:
			var seat_info = {
				player_id = 0,
				player_name = "",
				ready = false,
				load_ok = false,
			}
			camp_info.seats.append(seat_info)
		ready_room_info.camps.append(camp_info)

	var host = NetworkedMultiplayerENet.new()
	var ret = host.create_server(local_host_config.port, ProtoHall.Room.get_seat_count(ready_room_info))
	if ret != OK:
		var err = "create server failed, error code: %d" % ret
		Debug.error(err)
		Debug.alert(err, "error")
		return false
	get_tree().set_network_peer(host)

	var host_seat_info = ready_room_info.camps[0].seats[0]
	host_seat_info.player_id = 1
	host_seat_info.player_name = local_host_config.player_name
	host_seat_info.ready = true
	return true


func join_room(timeout = 10.0):
	var client = NetworkedMultiplayerENet.new()
	client.create_client(local_host_config.host, local_host_config.port)
	get_tree().set_network_peer(client)
	
	yield(get_tree().create_timer(timeout), "timeout")
	# check if connection status is connecting
	if client.get_connection_status() == 1 and \
	   client.get_unique_id() == get_tree().get_network_unique_id():
		get_tree().set_network_peer(null)
		_on_connection_failed()


func leave_room():
	rpc_id(1, "_on_leave_ready_room", get_tree().get_network_unique_id())
	get_tree().set_network_peer(null)


func switch_my_seat_ready_status():
	assert(not get_tree().is_network_server(), "called by client only")
	var id = get_tree().get_network_unique_id()
	var seat_info = ProtoHall.Room.try_get_player(ready_room_info, id)
	var pos = ProtoHall.Room.try_get_player_pos(ready_room_info, id)
	rpc_id(1, "_on_change_seat_info", {
		camp_idx = pos.camp_idx,
		seat_idx = pos.seat_idx,
		ready = not seat_info.ready,
	})


func swap_my_seat(to_camp_idx, to_seat_idx):
	rpc_id(1, "_on_change_seat_info", {
		camp_idx = to_camp_idx,
		seat_idx = to_seat_idx,
		ready = get_tree().is_network_server(),
	})


func open_seat(camp_idx, seat_idx):
	assert(get_tree().is_network_server(), "called by server only")
	var seat_info = ProtoHall.Room.try_get_seat(ready_room_info, camp_idx, seat_idx)
	if seat_info == null:
		return
	if seat_info.player_id == get_tree().get_network_unique_id():
		return
	if ProtoHall.Seat.is_open(seat_info):
		return
	if ProtoHall.Seat.is_player(seat_info):
		rpc_id(seat_info.player_id, "_on_ready_room_kicked")
		rpc("_on_ready_room_chat", {
			what = "%s get kicked" % seat_info.player_name,
			type = CHAT_SYSTEM
		})
	ProtoHall.Seat.open(seat_info)
	rpc("_on_ready_room_update", ready_room_info)


func close_seat(camp_idx, seat_idx):
	assert(get_tree().is_network_server(), "called by server only")
	var seat_info = ProtoHall.Room.try_get_seat(ready_room_info, camp_idx, seat_idx)
	if seat_info == null:
		return
	if seat_info.player_id == get_tree().get_network_unique_id():
		return
	if ProtoHall.Seat.is_close(seat_info):
		return
	if ProtoHall.Seat.is_player(seat_info):
		rpc_id(seat_info.player_id, "_on_ready_room_kicked")
		rpc("_on_ready_room_chat", {
			what = "%s get kicked" % seat_info.player_name,
			type = CHAT_SYSTEM
		})
	ProtoHall.Seat.close(seat_info)
	rpc("_on_ready_room_update", ready_room_info)


func set_robot(camp_idx, seat_idx, lv):
	assert(get_tree().is_network_server(), "called by server only")
	var seat_info = ProtoHall.Room.try_get_seat(ready_room_info, camp_idx, seat_idx)
	if seat_info == null:
		return
	if seat_info.player_id == get_tree().get_network_unique_id():
		return
	if ProtoHall.Seat.is_player(seat_info):
		rpc_id(seat_info.player_id, "_on_ready_room_kicked")
		rpc("_on_ready_room_chat", {
			what = "%s get kicked" % seat_info.player_name,
			type = CHAT_SYSTEM
		})
	ProtoHall.Seat.as_robot(seat_info, lv)
	rpc("_on_ready_room_update", ready_room_info)


func send_chat(what, type = CHAT_NORMAL):
	rpc("_on_ready_room_chat", {
		what = what,
		type = type,
	})


func start_game():
	ready_room_info.room_status = ROOM_COUNTDOWN
	rpc("_on_ready_room_update", ready_room_info)
	#get_tree().set_refuse_new_network_connections(true)
	var countdown = 1 if OS.is_debug_build() else DEFAULT_START_GAME_COUNTDOWN
	for i in range(countdown, 0, -1):
		send_chat("game will start after %d seconds..." % i, CHAT_SYSTEM)
		yield(get_tree().create_timer(1.0), "timeout")
		if ready_room_info.room_status != ROOM_COUNTDOWN:
			# canceled
			return
	ready_room_info.game_seed = OS.get_unix_time()
	rpc("_on_loading_game", ready_room_info)


func cancel_start_game():
	ready_room_info.room_status = ROOM_READY
	rpc("_on_ready_room_update", ready_room_info)
	#get_tree().set_refuse_new_network_connections(false)
