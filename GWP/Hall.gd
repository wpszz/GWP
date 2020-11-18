extends Control

var MAX_CACHE_CHATS = 100

var _selected_seat = {
	camp_idx = 0,
	seat_idx = 0,
	menu_idx = 0,
}

var _camp_uis = []

var _chat_cache = []


func _ready():
	
	NetCenter.bind_hall_net()

	Utility.connect_ex(NetHall, "sig_connection_success", self, "_on_connection_success")
	Utility.connect_ex(NetHall, "sig_connection_failed", self, "_on_connection_failed")
	Utility.connect_ex(NetHall, "sig_server_disconnected", self, "_on_server_disconnected")	
	Utility.connect_ex(NetHall, "sig_ready_room_is_full", self, "_on_ready_room_is_full")
	Utility.connect_ex(NetHall, "sig_ready_room_is_busy", self, "_on_ready_room_is_busy")
	Utility.connect_ex(NetHall, "sig_ready_room_update", self, "_on_ready_room_update")
	Utility.connect_ex(NetHall, "sig_ready_room_kicked", self, "_on_ready_room_kicked")
	Utility.connect_ex(NetHall, "sig_ready_room_chat", self, "_on_ready_room_chat")
	
	# fixed camp count	
	_camp_uis.append($ReadyRoom/Camp1)
	_camp_uis.append($ReadyRoom/Camp2)
	for i in _camp_uis.size():
		Utility.connect_ex(_camp_uis[i].seat_list, "sig_name_pressed", self, "_on_seat_name_pressed", i)
		Utility.connect_ex(_camp_uis[i].seat_list, "sig_swap_pressed", self, "_on_seat_swap_pressed", i)

	Utility.connect_ex($ReadyRoom/PopupMenu, "index_pressed", self, "_on_seat_menu_pressed")

	_enter_hall()


func _load_local_config():
	var cfg = NetHall.local_host_config
	$ConnectHall/Host.text = cfg.host
	$ConnectHall/Port.text = String(cfg.port)
	$ConnectHall/Name.text = cfg.player_name
	$ConnectHall/ErrorLabel.text = ""


func _save_local_config():
	var cfg = NetHall.local_host_config
	cfg.host = $ConnectHall/Host.text
	cfg.port = $ConnectHall/Port.text.to_int()
	cfg.player_name = $ConnectHall/Name.text


func _refresh_room():
	var room_info = NetHall.ready_room_info
	var game_about = SceneMgr.get_game_script(room_info.game_id).get_about()
	var camp_infos = room_info.camps
	
	$ReadyRoom/About/Name.text = game_about.game_name
	$ReadyRoom/About/Desc.text = game_about.introduction
	
	for i in camp_infos.size():
		var camp_info = camp_infos[i]
		var camp_ui = _camp_uis[i]
		_refresh_camp_info(camp_info, camp_ui, i)
	
	if get_tree().is_network_server():
		if room_info.room_status != NetHall.ROOM_READY:
			$ReadyRoom/Start.text = "Cancel Start"
			$ReadyRoom/Start.disabled = false
		else:
			$ReadyRoom/Start.text = "Start Game"
			$ReadyRoom/Start.disabled = not ProtoHall.Room.is_all_ready(room_info) or \
										not ProtoHall.Room.is_match_player_count(room_info, game_about)
	else:
		var id_self = get_tree().get_network_unique_id()
		var seat_info = ProtoHall.Room.try_get_player(room_info, id_self)
		$ReadyRoom/Start.text = "I'm not ready" if seat_info.ready else "I'm ready"
		$ReadyRoom/Start.disabled = room_info.room_status != NetHall.ROOM_READY
		
	$ReadyRoom/Leave.disabled = room_info.room_status != NetHall.ROOM_READY


func _refresh_camp_info(camp_info, camp_ui, camp_idx):
	var room_info = NetHall.ready_room_info
	camp_ui.seat_list.set_count(ProtoHall.Camp.get_seat_count(camp_info))
	camp_ui.set_title(camp_info.camp_name)
	var seat_infos = camp_info.seats
	var seat_uis = camp_ui.seat_list.seats
	var id_self = get_tree().get_network_unique_id()
	for i in seat_infos.size():
		var seat_info = seat_infos[i]
		var seat_ui = seat_uis[i]
		var camp_color = Utility.get_camp_index_color(camp_idx, i)
		var display_name = ProtoHall.Seat.get_display_name(seat_info)
		var display_status = ProtoHall.Seat.get_display_status(seat_info)
		var is_busy = room_info.room_status != NetHall.ROOM_READY
		var swappable = ProtoHall.Seat.is_open(seat_info) and not is_busy
		seat_ui.set_data(display_name, camp_color, display_status, is_busy, not swappable)
		var node_name = seat_ui.node_name as Button
		if id_self == seat_info.player_id:
			node_name.self_modulate = Color.green
		elif ProtoHall.Seat.is_player(seat_info):
			node_name.self_modulate = Color.lightskyblue
		elif ProtoHall.Seat.is_close(seat_info):
			node_name.self_modulate = Color.darkgray
		elif ProtoHall.Seat.is_robot(seat_info):
			node_name.self_modulate = Color.cadetblue	
		else:
			node_name.self_modulate = Color.white


func _set_hall_operation_enable(enable:bool):
	$ConnectHall/HostRoom.disabled = !enable
	$ConnectHall/JoinRoom.disabled = !enable


func _enter_hall():
	$ConnectHall.visible = true
	$ReadyRoom.visible = false
	_load_local_config()
	_set_hall_operation_enable(true)


func _enter_room():
	$ConnectHall.visible = false
	$ReadyRoom.visible = true
	_refresh_room()
	
	$ReadyRoom/Chat/Input.text = ""
	var content = ""
	_chat_cache.clear()
	_chat_cache.append("")
	for _i in range(1, MAX_CACHE_CHATS):
		_chat_cache.append("")
		content += "\n"
	$ReadyRoom/Chat/Content.text = content
	# invalid scroll setup inside init call, may be is a bug?
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	$ReadyRoom/Chat/Content.scroll_vertical = MAX_CACHE_CHATS


func _on_Host_pressed():
	_save_local_config()
	if not Utility.is_valid_name(NetHall.local_host_config.player_name, $ConnectHall/ErrorLabel):
		return
	if not Utility.is_valid_port(NetHall.local_host_config.port, $ConnectHall/ErrorLabel):
		return
	if not NetHall.host_room():
		return
	_enter_room()


func _on_Join_pressed():
	_save_local_config()
	if not Utility.is_valid_name(NetHall.local_host_config.player_name, $ConnectHall/ErrorLabel):
		return
	if not Utility.is_valid_ip_address(NetHall.local_host_config.host, $ConnectHall/ErrorLabel):
		return
	if not Utility.is_valid_port(NetHall.local_host_config.port, $ConnectHall/ErrorLabel):
		return
	NetHall.join_room()
	_set_hall_operation_enable(false)
	$ConnectHall/ErrorLabel.set_bbcode("Connecting...")


func _on_connection_success():
	# nothing handle
	pass


func _on_connection_failed():
	_set_hall_operation_enable(true)
	$ConnectHall/ErrorLabel.set_bbcode("[color=#ff0000]Connection Failed[/color]")	


func _on_server_disconnected():
	_enter_hall()


func _on_ready_room_is_full():
	_set_hall_operation_enable(true)


func _on_ready_room_is_busy():
	_set_hall_operation_enable(true)


func _on_ready_room_update():
	if $ReadyRoom.visible:
		_refresh_room()
	else:
		_enter_room()	


func _on_ready_room_kicked():
	_enter_hall()


func _on_ready_room_chat(what):
	_chat_cache.pop_front()
	_chat_cache.push_back(what)
	var content = _chat_cache[0]
	for i in range(1, MAX_CACHE_CHATS):
		content += "\n" + _chat_cache[i]
	$ReadyRoom/Chat/Content.text = content
	$ReadyRoom/Chat/Content.scroll_vertical = MAX_CACHE_CHATS


func _on_seat_name_pressed(seat_idx, camp_idx):
	if not get_tree().is_network_server():
		return
	var room_info = NetHall.ready_room_info
	var seat_info = room_info.camps[camp_idx].seats[seat_idx]
	if seat_info.player_id == get_tree().get_network_unique_id():
		return
	var seat_ui = _camp_uis[camp_idx].seat_list.seats[seat_idx]
	var dock = seat_ui.node_name
	$ReadyRoom/PopupMenu.clear()
	$ReadyRoom/PopupMenu.add_item("open")
	$ReadyRoom/PopupMenu.add_item("close")
	$ReadyRoom/PopupMenu.add_item(Utility.get_robot_classify_name(0))
	$ReadyRoom/PopupMenu.add_item(Utility.get_robot_classify_name(1))
	$ReadyRoom/PopupMenu.add_item(Utility.get_robot_classify_name(2))
	var rc = Rect2(dock.rect_global_position, dock.rect_size)
	$ReadyRoom/PopupMenu.popup(rc)	
	_selected_seat.camp_idx = camp_idx
	_selected_seat.seat_idx = seat_idx


func _on_seat_swap_pressed(seat_idx, camp_idx):
	var room_info = NetHall.ready_room_info
	var seat_info = room_info.camps[camp_idx].seats[seat_idx]
	if seat_info.player_id == get_tree().get_network_unique_id():
		return
	if ProtoHall.Seat.is_open(seat_info):
		NetHall.swap_my_seat(camp_idx, seat_idx)


func _on_seat_menu_pressed(index):
	_selected_seat.menu_idx = index
	if index == 0:
		NetHall.open_seat(_selected_seat.camp_idx, _selected_seat.seat_idx)
	elif index == 1:
		NetHall.close_seat(_selected_seat.camp_idx, _selected_seat.seat_idx)
	else:
		NetHall.set_robot(_selected_seat.camp_idx, _selected_seat.seat_idx, index - 2)


func _on_Start_pressed():
	var room_info = NetHall.ready_room_info
	if get_tree().is_network_server():
		if room_info.room_status != NetHall.ROOM_READY:
			NetHall.cancel_start_game()
		else:
			NetHall.start_game()
	else:
		NetHall.switch_my_seat_ready_status()


func _on_Leave_pressed():
	NetHall.leave_room()
	_enter_hall()


func _on_Send_pressed():
	if $ReadyRoom/Chat/Input.text.length() == 0:
		return
	NetHall.send_chat($ReadyRoom/Chat/Input.text)
	$ReadyRoom/Chat/Input.text = ""


func _on_Input_text_entered(_new_text):
	_on_Send_pressed()
