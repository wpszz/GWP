extends Node


static func _on_net_logic_frame(tank, _fp_delta):
	tank.ai_data.think_frame += 1
	var lv = ProtoHall.Seat.get_robot_lv(tank.camp_data.seat_info)
	var think_frame_need = Utility.get_robot_think_frame_interval(lv)

	var nearest = _query_nearest_enemy(tank)
	var nearest_enemy = nearest[0]
	var nearest_dis = nearest[1]

	if nearest_enemy == null:
		# no target to fire
		_reset_tank_op_key_status(tank)
		return

	var cur_pos = tank.fp_data.position
	var hit_pos = tank.get_global_fire_target_pos_fp()	
	var forward = tank.get_global_forward_fp()
	var enemy_pos = nearest_enemy.fp_data.position
	var temp_pos = FPMath.vec2_add(cur_pos, forward)

	var dir = FPMath.vec2_cross_magnitude(cur_pos, enemy_pos, hit_pos)
	var dir_tank = FPMath.vec2_cross_magnitude(cur_pos, temp_pos, enemy_pos)
	var tank_dis = FPMath.vec2_distance(cur_pos, enemy_pos)
	var fire_dis = FPMath.vec2_distance(cur_pos, hit_pos)

	if dir > 0:
		tank.op_key_status.turrent_turn = 1
	elif dir < 0:
		tank.op_key_status.turrent_turn = 2
	else:
		tank.op_key_status.turrent_turn = 0

	# scale = max(4 - lv, 2) / 2.0 = range[1.0, 2.0]
	var fds = FPMath.div(FPMath.from_number(max(4 - lv, 2)), FPMath.from_number(2))
	if nearest_dis <= FPMath.mul(tank.fp_data.fire_damage_radius, fds):
		tank.op_key_status.fire = 1
	else:
		tank.op_key_status.fire = 0

	if tank.ai_data.think_frame % think_frame_need != 0:
		return

	var is_too_far = FPMath.abs(tank_dis - fire_dis) > FPMath.from_number(100)

	if tank.op_key_status.turn == 0 or is_too_far:
		if dir_tank < 0:
			tank.op_key_status.turn = 1
		elif dir_tank > 0:
			tank.op_key_status.turn = 2
		else:
			tank.op_key_status.turn = NetGame.get_rand(0, 2)
	else:
		if NetGame.get_rand(1, 100) >= 70:
			tank.op_key_status.turn = 2 if tank.op_key_status.turn == 1 else 1

	if tank.op_key_status.move == 0 or is_too_far:
		if tank_dis > fire_dis:
			tank.op_key_status.move = 1
		elif tank_dis < fire_dis:
			tank.op_key_status.move = 2
	else:
		if NetGame.get_rand(1, 100) >= 70:
			tank.op_key_status.move = 2 if tank.op_key_status.move == 1 else 1

	if tank_dis > fire_dis:
		tank.op_key_status.turrent_pitch = 1
	elif tank_dis < fire_dis:
		tank.op_key_status.turrent_pitch = 2
	else:
		tank.op_key_status.turrent_pitch = 0

static func _reset_tank_op_key_status(tank):
	tank.op_key_status.move = 0
	tank.op_key_status.turn = 0
	tank.op_key_status.turrent_turn = 0
	tank.op_key_status.turrent_pitch = 0
	tank.op_key_status.fire = 0

static func _query_nearest_enemy(tank):
	var hit_pos = tank.get_global_fire_target_pos_fp()
	var camp_idx = tank.camp_data.camp_idx
	var world = tank.world
	var all_tanks = world._map_tanks
	var nearest_enemy = null
	var nearest_dis = 0
	for id in all_tanks:
		var enemy = all_tanks[id]
		if enemy.camp_data.camp_idx == camp_idx:
			continue
		if not enemy.is_alive_fp():
			continue
		var enemy_pos = enemy.fp_data.position
		var dis = FPMath.vec2_distance(hit_pos, enemy_pos)
		if nearest_enemy == null or nearest_dis > dis:
			nearest_enemy = enemy
			nearest_dis = dis
	return [nearest_enemy, nearest_dis]
