extends Node

# custom signals


# constants

var _current_listener = null

func _bind_net_listener(target):
	# called on both client and server side
	Utility.connect_ex(get_tree(), "network_peer_connected", target, "_on_peer_connected")
	Utility.connect_ex(get_tree(), "network_peer_disconnected", target,"_on_peer_disconnected")
	# called on client only
	Utility.connect_ex(get_tree(), "connected_to_server", target, "_on_connection_success")
	Utility.connect_ex(get_tree(), "connection_failed", target, "_on_connection_failed")
	Utility.connect_ex(get_tree(), "server_disconnected", target, "_on_server_disconnected")


func _unbind_net_listener(target):
	# called on both client and server side
	Utility.disconnect_ex(get_tree(), "network_peer_connected", target, "_on_peer_connected")
	Utility.disconnect_ex(get_tree(), "network_peer_disconnected", target,"_on_peer_disconnected")
	# called on client only
	Utility.disconnect_ex(get_tree(), "connected_to_server", target, "_on_connection_success")
	Utility.disconnect_ex(get_tree(), "connection_failed", target, "_on_connection_failed")
	Utility.disconnect_ex(get_tree(), "server_disconnected", target, "_on_server_disconnected")


func bind_hall_net():
	if _current_listener == NetHall:
		return
	if _current_listener != null:
		_unbind_net_listener(_current_listener)
	_bind_net_listener(NetHall)
	_current_listener = NetHall


func bind_game_net():
	if _current_listener == NetGame:
		return
	if _current_listener != null:
		_unbind_net_listener(_current_listener)
	_bind_net_listener(NetGame)
	_current_listener = NetGame
