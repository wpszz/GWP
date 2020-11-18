extends Node2D

signal sig_tank_fire(tank)
signal sig_tank_damaged(tank, value)

const MOVE_SPEED = 45
const TURN_SPEED = 25
const COLLIDE_RADIUS = 18
const TURRENT_TURN_SPEED = 30 # must be greater than TURN_SPEED
const TURRENT_FIRE_RANGE_MIN = 100
const TURRENT_FIRE_RANGE_MAX = 500
const TURRENT_FIRE_RANGE_DEFAULT = 300
const TURRENT_FIRE_RANGE_ADJUST_SPEED = 100
const FIRE_INTERVAL = 2
const FIRE_DAMAGE_RADIUS = 25
const FIRE_DAMAGE_MAX = 10
const ARMOR_MAX = 100
const AMMO_MAX = 64

var op_key_status = {
	move = 0, 			# 0:idle 1:move_up 2:move_down 
	turn = 0, 			# 0:idle 1:turn_left 2:turn_right
	fire = 0, 			# 0:idle 1:fire
	turrent_turn = 0,	# 0:idle 1:turn_left 2:turn_right
	turrent_pitch = 0,	# 0:idle 1:pitch_up 2:pitch_down
}

var ai_data = {
	think_frame = 0
}

var camp_data = {}

# FP data
var fp_data = {
	#position
	#rotation_degrees
	#speed
	#turn_speed
	#collide_radius
	#turrent_turn_speed
	#turrent_position
	#turrent_rotation_degrees
	#turrent_length
	#turrent_fire_range
	#turrent_fire_range_min
	#turrent_fire_range_max
	#turrent_fire_range_adjust_speed
	#fire_interval
	#fire_last_time
	#fire_damage_radius
	#fire_damage_max
	#armor_max
	#armor_cur
	#ammo_max
	#ammo_cur
}

# Predict data
var predict_data = {
	#op_key_status
	#fp_data
}
func _capture_predict_data():
	# copy last net logic frame status to predict data
	predict_data.op_key_status = op_key_status.duplicate(true)
	predict_data.fp_data = fp_data.duplicate(true)

# ref of the world instance
var world = null

# ref of fired target position of prediction
var fired_target_prediction = null

# prefabs
var _fired_prefab = preload("res://games/TankWar/Fired.tscn")
var _tank_target_prefab = preload("res://games/TankWar/TankTarget.tscn")

func _fp_degrees_to_fp_forward(fp_degrees):
	# right-hand system(+y-axis is point to bottom)
	fp_degrees = FPMath.sub(fp_degrees, FPMath.from_number(90))
	var fp_rad = FPMath.deg2rad(fp_degrees)
	var forward = [
		FPMath.cos(fp_rad),
		FPMath.sin(fp_rad),
	]
	return forward

func _on_net_logic_frame(fp_delta, is_pure_logic):
	if not is_alive_fp():
		return

	_perform_oks_logic(fp_delta, op_key_status, fp_data)

	if is_pure_logic:
		return

	# new net logic frame arrived, so discard old predict data
	_capture_predict_data()

	# update presentation state of tank for rendering
	_update_for_rendering(fp_data, true)

func _on_local_predict_frame(fp_delta):
	if not is_alive_fp():
		return

	# dont predict fire instruction
	predict_data.op_key_status.fire = 0

	_perform_oks_logic(fp_delta, predict_data.op_key_status, predict_data.fp_data)

	# update presentation state of tank for rendering
	_update_for_rendering(predict_data.fp_data, true)
	
	#print("_on_local_predict_frame:", predict_data.op_key_status)

func _perform_oks_logic(fp_delta, oks, fpd):
	# only turnable when is moving
	if oks.move != 0:
		if oks.turn == 1:
			var delta = FPMath.mul(fp_delta, fpd.turn_speed)
			fpd.rotation_degrees = FPMath.sub(fpd.rotation_degrees, delta)
			fpd.rotation_degrees = FPMath.deg_normalize(fpd.rotation_degrees)
		elif oks.turn == 2:
			var delta = FPMath.mul(fp_delta, fpd.turn_speed)
			fpd.rotation_degrees = FPMath.add(fpd.rotation_degrees, delta)
			fpd.rotation_degrees = FPMath.deg_normalize(fpd.rotation_degrees)

	if oks.move == 1:
		var delta = FPMath.mul(fp_delta, fpd.speed)
		var forward = _fp_degrees_to_fp_forward(fpd.rotation_degrees)
		var advance = FPMath.vec2_scale(forward, delta)
		world.fp_move_and_stop(self, advance, fpd)
	elif oks.move == 2:
		var delta = -FPMath.mul(fp_delta, fpd.speed)
		var forward = _fp_degrees_to_fp_forward(fpd.rotation_degrees)
		var advance = FPMath.vec2_scale(forward, delta)
		world.fp_move_and_stop(self, advance, fpd)

	if oks.turrent_turn == 1:
		var delta = FPMath.mul(fp_delta, fpd.turrent_turn_speed)
		fpd.turrent_rotation_degrees = FPMath.sub(fpd.turrent_rotation_degrees, delta)
		fpd.turrent_rotation_degrees = FPMath.deg_normalize(fpd.turrent_rotation_degrees)
	elif oks.turrent_turn == 2:
		var delta = FPMath.mul(fp_delta, fpd.turrent_turn_speed)
		fpd.turrent_rotation_degrees = FPMath.add(fpd.turrent_rotation_degrees, delta)
		fpd.turrent_rotation_degrees = FPMath.deg_normalize(fpd.turrent_rotation_degrees)

	if oks.turrent_pitch == 1:
		var delta = FPMath.mul(fp_delta, fpd.turrent_fire_range_adjust_speed)
		fpd.turrent_fire_range = FPMath.add(fpd.turrent_fire_range, delta)
		fpd.turrent_fire_range = FPMath.clamp(fpd.turrent_fire_range, fpd.turrent_fire_range_min, fpd.turrent_fire_range_max)
	elif oks.turrent_pitch == 2:
		var delta = FPMath.mul(fp_delta, fpd.turrent_fire_range_adjust_speed)
		fpd.turrent_fire_range = FPMath.sub(fpd.turrent_fire_range, delta)
		fpd.turrent_fire_range = FPMath.clamp(fpd.turrent_fire_range, fpd.turrent_fire_range_min, fpd.turrent_fire_range_max)

	if oks.fire == 1:
		var delta = FPMath.sub(world.fp_data.net_total_time, fpd.fire_last_time)
		if delta >= fpd.fire_interval and fpd.ammo_cur > 0:
			fpd.fire_last_time = world.fp_data.net_total_time
			fpd.ammo_cur = FPMath.sub(fpd.ammo_cur, FPMath.one)
			var target_pos = get_global_fire_target_pos_fp()
			world.fp_explosion(target_pos, fpd.fire_damage_radius, fpd.fire_damage_max, self)
			world.create_sound("fire")
			play_fire_animation()
			emit_signal("sig_tank_fire", self)

func get_global_forward_fp():
	return _fp_degrees_to_fp_forward(fp_data.rotation_degrees)

func get_global_turret_mat_fp():
	var mat_tank = FPMath.matrix23(fp_data.position, fp_data.rotation_degrees)
	var mat_turret = FPMath.matrix23(fp_data.turrent_position, fp_data.turrent_rotation_degrees)
	return FPMath.matrix23_mul(mat_tank, mat_turret)

func get_global_muzzle_pos_fp():
	var mat = get_global_turret_mat_fp()
	var local_muzzle_pos = [0, -fp_data.turrent_length]
	return FPMath.matrix23_xform(mat, local_muzzle_pos)

func get_global_fire_target_pos_fp():
	var mat = get_global_turret_mat_fp()
	var local_fire_target_pos = [0, -FPMath.add(fp_data.turrent_length, fp_data.turrent_fire_range)]
	return FPMath.matrix23_xform(mat, local_fire_target_pos)

func is_alive_fp():
	return fp_data.armor_cur > 0

func receive_damaged_fp(fp_damage, _source):
	fp_data.armor_cur = FPMath.sub(fp_data.armor_cur, fp_damage)
	if fp_data.armor_cur <= 0:
		fp_data.armor_cur = 0
		var fired = _fired_prefab.instance()
		self.add_child(fired)
	emit_signal("sig_tank_damaged", self, -FPMath.to_float(fp_damage))

func init_data_fp():
	fp_data.position = FPMath.from_vec2(self.position)
	fp_data.rotation_degrees = FPMath.from_number(self.rotation_degrees)
	fp_data.speed = FPMath.from_number(MOVE_SPEED)
	fp_data.turn_speed = FPMath.from_number(TURN_SPEED)
	fp_data.collide_radius = FPMath.from_number(COLLIDE_RADIUS)
	fp_data.turrent_turn_speed = FPMath.from_number(TURRENT_TURN_SPEED)
	fp_data.turrent_position = FPMath.from_vec2($Turret.position)
	fp_data.turrent_rotation_degrees = 0
	fp_data.turrent_length = FPMath.from_number($Turret/Muzzle.position.length())
	fp_data.turrent_fire_range = FPMath.from_number(TURRENT_FIRE_RANGE_DEFAULT)
	fp_data.turrent_fire_range_min = FPMath.from_number(TURRENT_FIRE_RANGE_MIN)
	fp_data.turrent_fire_range_max = FPMath.from_number(TURRENT_FIRE_RANGE_MAX)
	fp_data.turrent_fire_range_adjust_speed = FPMath.from_number(TURRENT_FIRE_RANGE_ADJUST_SPEED)
	fp_data.fire_interval = FPMath.from_number(FIRE_INTERVAL)
	fp_data.fire_last_time = FPMath.from_number(-FIRE_INTERVAL)
	fp_data.fire_damage_radius = FPMath.from_number(FIRE_DAMAGE_RADIUS)
	fp_data.fire_damage_max = FPMath.from_number(FIRE_DAMAGE_MAX)
	fp_data.armor_max = FPMath.from_number(ARMOR_MAX)
	fp_data.armor_cur = FPMath.from_number(ARMOR_MAX)
	fp_data.ammo_max = FPMath.from_number(AMMO_MAX)
	fp_data.ammo_cur = FPMath.from_number(AMMO_MAX)

	# init predict data
	_capture_predict_data()

	# init rendering
	_update_for_rendering(fp_data)

func set_camp_and_seat(camp_idx:int, seat_idx:int, seat_info, my_pos):
	var color = Utility.get_camp_index_color(camp_idx, seat_idx) 
	$Base.modulate = color
	$Turret.modulate = color
	
	camp_data.camp_idx = camp_idx
	camp_data.seat_idx = seat_idx
	camp_data.seat_info = seat_info
	
	if camp_idx == 1:
		set_rotation(180)
	else:
		set_rotation(0)

	$HUD/Name.text = seat_info.player_name
	if my_pos.camp_idx == camp_idx:
		$HUD/Name.modulate = Color.chartreuse if my_pos.seat_idx == seat_idx else Color.deepskyblue
	else:
		$HUD/Name.modulate = Color.crimson

func _update_for_rendering(fpd, smooth_lerp = false):
	# update presentation state of tank for rendering
	set_position(FPMath.to_vec2(fpd.position), smooth_lerp)
	set_rotation(FPMath.to_float(fpd.rotation_degrees), smooth_lerp)
	
	_update_turret_rotation(fpd, smooth_lerp)
	_update_fired_target_prediction(fpd, smooth_lerp)

func set_position(pos, smooth_lerp = false):
	self.position = _get_position_with_smooth_lerp(self.position, pos, smooth_lerp)
	$HUD.offset = self.global_position

func set_rotation(degrees, smooth_lerp = false):
	self.rotation_degrees = _get_rotation_with_smooth_lerp(self.rotation_degrees, degrees, smooth_lerp)

func _update_turret_rotation(fpd, smooth_lerp = false):
	var degrees = FPMath.to_float(fpd.turrent_rotation_degrees)
	$Turret.rotation_degrees = _get_rotation_with_smooth_lerp($Turret.rotation_degrees, degrees, smooth_lerp)

func _update_fired_target_prediction(fpd, smooth_lerp = false):
	if fired_target_prediction == null:
		return

	var mat : Transform2D = self.transform * $Turret.transform
	var local_fire_target_pos = Vector2(0, -FPMath.to_float(FPMath.add(fpd.turrent_length, fpd.turrent_fire_range)))
	var target_pos = mat.xform(local_fire_target_pos)
	fired_target_prediction.position = _get_position_with_smooth_lerp(
		fired_target_prediction.position, target_pos, smooth_lerp)
	var local_muzzle_pos = Vector2(0, -FPMath.to_float(fpd.turrent_length))
	var muzzle_pos = mat.xform(local_muzzle_pos)	
	fired_target_prediction.set_path_target(muzzle_pos)

func attach_fire_target_prediction():
	# create local player fired target position of prediction
	fired_target_prediction = _tank_target_prefab.instance()
	world.add_child(fired_target_prediction)

func play_fire_animation():
	$Turret/Muzzle/Fire/AnimationPlayer.play("Fire")

func _get_smooth_lerp_t():
	return 0.5

func _get_position_with_smooth_lerp(from, to, smooth_lerp):
	if smooth_lerp:
		return lerp(from, to, _get_smooth_lerp_t())
	return to

func _get_rotation_with_smooth_lerp(from, to, smooth_lerp):
	if smooth_lerp:
		var rad_from = deg2rad(from)
		var rad_to = deg2rad(to)
		return rad2deg(lerp_angle(rad_from, rad_to, _get_smooth_lerp_t()))
	return to	
