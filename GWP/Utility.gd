extends Node


static func connect_ex(src:Object, src_signal:String, dest:Object, dest_action:String, arg = null):
	if arg == null:
		if src.connect(src_signal, dest, dest_action) != OK:
			# to get rid of connect warning
			#print("connect failed: ", src, " ", src_signal, " ", dest, " ", dest_action)
			pass
	else:
		if src.connect(src_signal, dest, dest_action, [arg]) != OK:
			pass


static func disconnect_ex(src:Object, src_signal:String, dest:Object, dest_action:String):
	if src.is_connected(src_signal, dest, dest_action):
		src.disconnect(src_signal, dest, dest_action)


static func is_valid_ip_address(ip:String, warning:RichTextLabel):
	if ip.is_valid_ip_address():
		return true
	warning.set_bbcode("[color=#ff0000]Invalid IP Address[/color]")	
	return false


static func is_valid_port(port:int, warning:RichTextLabel):
	if port >= 1 and port <= 65535:
		return true
	warning.set_bbcode("[color=#ff0000]Invalid Port[/color]")		
	return false


static func is_valid_name(name:String, warning:RichTextLabel):
	if name.length() >= 2 and name.length() <= 20:
		return true
	warning.set_bbcode("[color=#ff0000]Invalid Name[/color]")	
	return false


var _camp_colors = [
	Color.crimson,
	Color.gold,
	Color.aliceblue,
	Color.aqua,
	Color.blueviolet,
	Color.chartreuse,	
	Color.brown,
	Color.cadetblue,
	Color.chocolate,
	Color.cornflower,
]
func get_camp_index_color(camp:int, index:int) -> Color:
	var id = camp * 5 + index
	id = id % _camp_colors.size()
	return _camp_colors[id]
	


var _robot_classify_names = [
	"robot(stupid)",
	"robot(smart)",
	"robot(genius)",
]
func get_robot_classify_name(lv:int) -> String:
	assert(lv >= 0, "robot lv must be in range[0, 255]")
	if lv >= _robot_classify_names.size():
		return "robot(unknown)"
	return _robot_classify_names[lv]

var _robot_index_current = 1
func get_robot_unique_id(lv:int)->int:
	assert(lv >= 0, "robot lv must be in range[0, 255]")
	var id = -((_robot_index_current << 8) | lv)
	_robot_index_current += 1
	return id

var _robot_think_frame_intervals = [
	40,
	20,
	10,
]
func get_robot_think_frame_interval(lv:int)->int:
	assert(lv >= 0, "robot lv must be in range[0, 255]")
	if lv >= _robot_think_frame_intervals.size():
		return _robot_think_frame_intervals.back()
	return _robot_think_frame_intervals[lv]
