extends Node

# static API for seat info processing
class Seat:
	# seat_info(dictionary):
	# 	var player_id = 0
	#	var player_name = ""
	#	var ready = false
	#	var load_ok = false

	static func is_player(seat_info):
		return seat_info.player_id > 0

	static func is_open(seat_info):
		return seat_info.player_id == 0

	static func is_close(seat_info):
		return seat_info.player_id == -1

	static func is_robot(seat_info):
		return seat_info.player_id < -1

	static func open(seat_info):
		seat_info.player_id = 0
		seat_info.player_name = ""
		seat_info.ready = false

	static func close(seat_info):
		seat_info.player_id = -1
		seat_info.player_name = ""
		seat_info.ready = false

	static func as_robot(seat_info, lv):
		seat_info.player_id = Utility.get_robot_unique_id(lv)
		seat_info.player_name = Utility.get_robot_classify_name(lv)
		seat_info.ready = false

	static func get_robot_lv(seat_info):
		return (-seat_info.player_id) & 0xff

	static func get_display_name(seat_info):
		if is_player(seat_info):
			return seat_info.player_name
		if is_open(seat_info):
			return "open"
		if is_robot(seat_info):
			return seat_info.player_name
		return "close"

	static func get_display_status(seat_info):
		if not is_player(seat_info):
			return ""
		if seat_info.player_id == 1:
			return "host"
		if seat_info.ready:
			return "ready"
		return "unready"

	static func duplicate(seat_info, _deep = false):
		return seat_info.duplicate(_deep)


# static API for camp info processing
class Camp:
	# camp_info(dictionary):
	#	camp_name = ""
	# 	seats = [seat_info]

	static func get_seat_count(camp_info):
		return camp_info.seats.size()

	static func get_player_count(camp_info):
		var cnt = 0
		for seat in camp_info.seats:
			if Seat.is_player(seat):
				cnt += 1
		return cnt

	static func get_open_count(camp_info):
		var cnt = 0
		for seat in camp_info.seats:
			if Seat.is_open(seat):
				cnt += 1
		return cnt

	static func get_robot_count(camp_info):
		var cnt = 0
		for seat in camp_info.seats:
			if Seat.is_robot(seat):
				cnt += 1
		return cnt

	static func is_all_ready(camp_info):
		for seat in camp_info.seats:
			if Seat.is_player(seat) and not seat.ready:
				return false
		return true

	static func is_all_load_ok(camp_info):
		for seat in camp_info.seats:
			if Seat.is_player(seat) and not seat.load_ok:
				return false
		return true

	static func try_get_player(camp_info, player_id):
		for seat in camp_info.seats:
			if seat.player_id == player_id:
				return seat
		return null

	static func try_insert_player(camp_info, seat_info):
		if try_get_player(camp_info, seat_info.player_id) != null:
			return false
		for i in range(0, camp_info.seats.size()):
			if Seat.is_open(camp_info.seats[i]):
				camp_info.seats[i] = seat_info
				return true
		return false

	static func try_remove_player(camp_info, player_id):
		for seat in camp_info.seats:
			if seat.player_id == player_id:
				Seat.open(seat)
				return true
		return false

	static func try_get_seat_idx(camp_info, player_id):
		for i in range(0, camp_info.seats.size()):
			if camp_info.seats[i].player_id == player_id:
				return i
		return -1

	static func duplicate(camp_info, _deep = false):
		return camp_info.duplicate(_deep)


# static API for room info processing
class Room:
	# room_info(dictionary):
	#	room_name = ""
	#	game_id = ""
	#	camps = [camp_info]
	#	room_status = ROOM_READY
	#	game_seed = <timestamp(int) of game start>

	static func get_seat_count(room_info):
		var cnt = 0
		for camp in room_info.camps:
			cnt += Camp.get_seat_count(camp)
		return cnt

	static func get_player_count(room_info):
		var cnt = 0
		for camp in room_info.camps:
			cnt += Camp.get_player_count(camp)
		return cnt

	static func get_open_count(room_info):
		var cnt = 0
		for camp in room_info.camps:
			cnt += Camp.get_open_count(camp)
		return cnt

	static func is_all_ready(room_info):
		for camp in room_info.camps:
			if not Camp.is_all_ready(camp):
				return false
		return true

	static func is_match_player_count(room_info, game_about):
		for i in room_info.camps.size():
			var cnt = Camp.get_player_count(room_info.camps[i]) + Camp.get_robot_count(room_info.camps[i])
			if cnt < game_about.camp_configs[i].min_players:
				return false
		return true

	static func is_all_load_ok(room_info):
		for camp in room_info.camps:
			if not Camp.is_all_load_ok(camp):
				return false
		return true

	static func try_get_player(room_info, player_id):
		for camp in room_info.camps:
			var seat = Camp.try_get_player(camp, player_id)
			if seat != null:
				return seat
		return null

	static func try_insert_player(room_info, seat_info):
		if try_get_player(room_info, seat_info.player_id) != null:
			return false
		for camp in room_info.camps:
			if Camp.try_insert_player(camp, seat_info):
				return true
		return false

	static func try_remove_player(room_info, player_id):
		for camp in room_info.camps:
			if Camp.try_remove_player(camp, player_id):
				return true
		return false

	static func try_get_seat(room_info, camp_idx, seat_idx):
		if camp_idx < 0 or camp_idx >= room_info.camps.size():
			return null
		if seat_idx < 0 or seat_idx >= room_info.camps[camp_idx].seats.size():
			return null
		return room_info.camps[camp_idx].seats[seat_idx]

	static func try_get_player_pos(room_info, player_id):
		for i in range(0, room_info.camps.size()):
			var seat_idx = Camp.try_get_seat_idx(room_info.camps[i], player_id)
			if seat_idx != -1:
				return {
					camp_idx = i,
					seat_idx = seat_idx
				}
		return null

	static func duplicate(room_info, _deep = false):
		return room_info.duplicate(_deep)
