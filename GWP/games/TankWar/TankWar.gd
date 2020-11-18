extends Node2D

static func get_about():
	return {
		game_name = "Tank Wars",
		camp_configs = [
			{
				camp_name = "Earth",
				min_players = 0 if OS.is_debug_build() else 1,
				max_players = 5,
			},
			{
				camp_name = "Mars",
				min_players = 0 if OS.is_debug_build() else 1,
				max_players = 5,
			}
		],
		introduction = "The war between Earth and Mars.",
	}

# prefabs
var _hud = preload("res://games/TankWar/TankHUD.tscn").instance()
var _tank_prefab = preload("res://games/TankWar/Tank.tscn")
var _explosion_prefab = preload("res://games/TankWar/Explosion.tscn")
var _audio_player_prefab = preload("res://games/TankWar/AudioPlayer.tscn")

# AI
var _tank_ai = preload("res://games/TankWar/TankAI.gd")

# FP data
var fp_data = {
	spawn_points = [[], []],
	bounds = [[], []],
	net_delta = 0,
	net_total_time = 0,
}

func get_spawn_points_fp(camp, index):
	return fp_data.spawn_points[camp][index]
func get_spawn_points(camp, index):
	var fp_pos = fp_data.spawn_points[camp][index]
	return FPMath.to_vec2(fp_pos)

# tank instances
var _map_tanks = {}
func get_player_tank(player_id):
	if _map_tanks.has(player_id):
		return _map_tanks[player_id]
	return null
func get_my_tank() -> Node2D:
	return get_player_tank(get_tree().get_network_unique_id())

# net frame data
const NET_SYNC_FREQ = 30
#const NET_FRAME_QUEUE_SIZE = NET_SYNC_FREQ * 10
#const NET_PREDICTION_FRAME_COUNT = NET_SYNC_FREQ * 1
var _net_frames = []
var _net_prediction_frames = []
var _net_frame_recv_count = 0
var _net_frame_perform_count = 0
var _server_current_frame = {}
func set_server_current_frame_data(player_id, shift_status, mask):
	var cur_status = _server_current_frame[player_id] if _server_current_frame.has(player_id) else 0
	cur_status = shift_status | (cur_status & mask)
	_server_current_frame[player_id] = cur_status
	#print("server_current_frame:", str(_server_current_frame))

func _ready():
	# paused until notified by server
	get_tree().set_pause(true)

	# set _physics_process iterations per second
	Engine.iterations_per_second = NET_SYNC_FREQ	

	# get spawn points
	var spawn_points = [[], []]
	for i in 5:
		# Earth spawn points
		spawn_points[0].append($SpawnPoints.get_node("E%d" % i).position)
		# Mars spawn points
		spawn_points[1].append($SpawnPoints.get_node("M%d" % i).position)
	
	# spawn initial tanks
	var room_info = NetGame.game_room_info
	var my_id = get_tree().get_network_unique_id()
	var my_pos = ProtoHall.Room.try_get_player_pos(room_info, my_id)
	for i in room_info.camps.size():
		var camp_info = room_info.camps[i]
		for j in camp_info.seats.size():
			var seat_info = camp_info.seats[j]
			if ProtoHall.Seat.is_player(seat_info) or ProtoHall.Seat.is_robot(seat_info):
				var tank = _tank_prefab.instance()
				tank.world = self
				self.add_child(tank)
				tank.set_position(spawn_points[i][j])
				tank.set_camp_and_seat(i, j, seat_info, my_pos)
				_map_tanks[seat_info.player_id] = tank
				if OS.is_debug_build():
					tank.attach_fire_target_prediction()
					
	var my_tank = get_my_tank()

	# create local player fired target position of prediction
	if not OS.is_debug_build():
		my_tank.attach_fire_target_prediction()

	# init all dynamic object fp data
	self.init_data_fp(spawn_points)

	# make the game view nice for both camps
	if my_tank.camp_data.camp_idx == 1:
		self.rotation_degrees = 180

	# HUD
	_hud.world = self
	self.add_child(_hud)


func init_data_fp(spawn_points):
	# get spawn points
	for i in 5:
		# Earth spawn points
		fp_data.spawn_points[0].append(FPMath.from_vec2(spawn_points[0][i]))
		# Mars spawn points
		fp_data.spawn_points[1].append(FPMath.from_vec2(spawn_points[1][i]))
	
	# bounds of moving
	fp_data.bounds[0].append(FPMath.from_vec2($EarthBound/Min.position))
	fp_data.bounds[0].append(FPMath.from_vec2($EarthBound/Max.position))
	fp_data.bounds[1].append(FPMath.from_vec2($MarsBound/Min.position))
	fp_data.bounds[1].append(FPMath.from_vec2($MarsBound/Max.position))
	
	# net logic frame delta fp time
	fp_data.net_delta = FPMath.div(FPMath.from_number(1), FPMath.from_number(NET_SYNC_FREQ))
	
	# all tanks fp data
	for id in _map_tanks:
		var tank = _map_tanks[id]
		tank.init_data_fp()


func _physics_process(_delta):
	#print(_delta, "   ", fp_data.net_delta, "  ", FPMath.to_float(fp_data.net_delta))
	# collect tank op keys
	if Input.is_action_just_pressed("tank_move_up"):
		_rpc_master_and_local("_on_move_status_change", 1)
	if Input.is_action_just_released("tank_move_up"):
		_rpc_input_release("_on_move_status_change", 0, "tank_move_back", 2)
		#_rpc_master_and_local("_on_move_status_change", 0)
	if Input.is_action_just_pressed("tank_move_back"):
		_rpc_master_and_local("_on_move_status_change", 2)
	if Input.is_action_just_released("tank_move_back"):
		_rpc_input_release("_on_move_status_change", 0, "tank_move_up", 1)
		#_rpc_master_and_local("_on_move_status_change", 0)
	if Input.is_action_just_pressed("tank_turn_left"):
		_rpc_master_and_local("_on_trun_status_change", 1)
	if Input.is_action_just_released("tank_turn_left"):
		_rpc_input_release("_on_trun_status_change", 0, "tank_turn_right", 2)
		#_rpc_master_and_local("_on_trun_status_change", 0)
	if Input.is_action_just_pressed("tank_turn_right"):
		_rpc_master_and_local("_on_trun_status_change", 2)
	if Input.is_action_just_released("tank_turn_right"):
		_rpc_input_release("_on_trun_status_change", 0, "tank_turn_left", 1)
		#_rpc_master_and_local("_on_trun_status_change", 0)
	if Input.is_action_just_pressed("tank_fire"):
		_rpc_master_and_local("_on_fire_status_change", 1)
	if Input.is_action_just_released("tank_fire"):
		_rpc_master_and_local("_on_fire_status_change", 0)
	if Input.is_action_just_pressed("tank_turret_turn_left"):
		_rpc_master_and_local("_on_turrent_turn_status_change", 1)
	if Input.is_action_just_released("tank_turret_turn_left"):
		_rpc_input_release("_on_turrent_turn_status_change", 0, "tank_turret_turn_right", 2)
		#_rpc_master_and_local("_on_turrent_turn_status_change", 0)
	if Input.is_action_just_pressed("tank_turret_turn_right"):
		_rpc_master_and_local("_on_turrent_turn_status_change", 2)
	if Input.is_action_just_released("tank_turret_turn_right"):
		_rpc_input_release("_on_turrent_turn_status_change", 0, "tank_turret_turn_left", 1)
		#_rpc_master_and_local("_on_turrent_turn_status_change", 0)
	if Input.is_action_just_pressed("tank_turret_pitch_up"):
		_rpc_master_and_local("_on_turrent_pitch_status_change", 1)
	if Input.is_action_just_released("tank_turret_pitch_up"):
		_rpc_input_release("_on_turrent_pitch_status_change", 0, "tank_turret_pitch_down", 2)
		#_rpc_master_and_local("_on_turrent_pitch_status_change", 0)
	if Input.is_action_just_pressed("tank_turret_pitch_down"):
		_rpc_master_and_local("_on_turrent_pitch_status_change", 2)
	if Input.is_action_just_released("tank_turret_pitch_down"):
		_rpc_input_release("_on_turrent_pitch_status_change", 0, "tank_turret_pitch_up", 1)
		#_rpc_master_and_local("_on_turrent_pitch_status_change", 0)

	# server sync current frame data to all clients
	if get_tree().is_network_server():
		rpc("_on_net_frame", _server_current_frame)

	var local_frame = _server_current_frame
	_server_current_frame = {}

	# perform net frames 
	if _net_frames.size() > 0:
		while _net_frames.size() > 1:
			#print("perform pure logic frame: ", _net_frame_perform_count, ", pool size: ", _net_frames.size())
			_perform_net_logic_frame(_net_frames.pop_front(), true)
		_perform_net_logic_frame(_net_frames.pop_front(), false)
	else:
		#print("missing logic frame: ", _net_frame_perform_count)
		_perform_local_predict_frame(local_frame)

func _perform_net_logic_frame(frame, is_pure_logic):
	_net_frame_perform_count += 1
	fp_data.net_total_time = FPMath.add(fp_data.net_total_time, fp_data.net_delta)
	# update tank op staus
	for id in frame:
		var status = frame[id]
		var tank = get_player_tank(id)
		_update_tank_op_key_status(tank.op_key_status, status)
	# update tank net logic frame
	for id in _map_tanks:
		var tank = _map_tanks[id]
		if ProtoHall.Seat.is_robot(tank.camp_data.seat_info):
			_tank_ai._on_net_logic_frame(tank, fp_data.net_delta)
		tank._on_net_logic_frame(fp_data.net_delta, is_pure_logic)
	#print("_perform_net_logic_frame(%d):" % _net_frame_perform_count, str(frame))

func _perform_local_predict_frame(local_frame):
	# client only
	var my_tank = get_my_tank()
	# id is zero since non-rpc call
	if local_frame.has(0):
		var status = local_frame[0]
		_update_tank_op_key_status(my_tank.predict_data.op_key_status, status)
	my_tank._on_local_predict_frame(fp_data.net_delta)

func _update_tank_op_key_status(oks, status):
	var new_move = status & 0x0000f
	var new_turn = (status & 0x000f0) >> 4
	var new_fire = (status & 0x00f00) >> 8
	var new_turrent_turn = (status & 0x0f000) >> 12
	var new_turrent_pitch = (status & 0xf0000) >> 16
	oks.move = (new_move & 0x7) if new_move != 0 else oks.move
	oks.turn = (new_turn & 0x7) if new_turn != 0 else oks.turn
	oks.fire = (new_fire & 0x7) if new_fire != 0 else oks.fire
	oks.turrent_turn = (new_turrent_turn & 0x7) if new_turrent_turn != 0 else oks.turrent_turn
	oks.turrent_pitch = (new_turrent_pitch & 0x7) if new_turrent_pitch != 0 else oks.turrent_pitch

func fp_get_tank_aabb(fpd):
	var fp_pos = fpd.position
	var fp_collide_radius = fpd.collide_radius
	return [
		[FPMath.sub(fp_pos[0], fp_collide_radius), FPMath.sub(fp_pos[1], fp_collide_radius)],
		[FPMath.add(fp_pos[0], fp_collide_radius), FPMath.add(fp_pos[1], fp_collide_radius)],
	]

func fp_move_and_stop(tank, fp_advance, fpd):
	var fp_bound = fp_data.bounds[tank.camp_data.camp_idx]
	var fp_min = fp_bound[0]
	var fp_max = fp_bound[1]
	var fp_pos = fpd.position
	fp_pos = FPMath.vec2_add(fp_pos, fp_advance, fp_pos)
	# check collision with other tanks
	var fp_aabb = fp_get_tank_aabb(fpd)
	for id in _map_tanks:
		var tank_other = _map_tanks[id]
		if tank == tank_other:
			continue
		var fp_aabb_other = fp_get_tank_aabb(tank_other.fp_data)
		if FPMath.aabb_collide(fp_aabb, fp_aabb_other):
			# simple back to origin
			fp_pos = FPMath.vec2_sub(fp_pos, fp_advance, fp_pos)
			return
	fp_pos[0] = min(max(fp_pos[0], fp_min[0]), fp_max[0])
	fp_pos[1] = min(max(fp_pos[1], fp_min[1]), fp_max[1])

func fp_explosion(fp_pos, fp_radius, fp_max_damage, _source = null):
	var explosion = _explosion_prefab.instance()
	self.add_child(explosion)
	explosion.position = FPMath.to_vec2(fp_pos)
	create_sound("explosion")
	
	for id in _map_tanks:
		var tank = _map_tanks[id]
		if not tank.is_alive_fp():
			continue
		var dis = FPMath.vec2_distance(fp_pos, tank.fp_data.position)
		var safe_dis = FPMath.add(fp_radius, tank.fp_data.collide_radius)
		if dis < safe_dis:
			var fp_t = FPMath.div(dis, safe_dis)
			var fp_damage = FPMath.lerp(fp_max_damage, 0, fp_t)
			fp_damage = FPMath.ceil(fp_damage)
			tank.receive_damaged_fp(fp_damage, _source)

func create_sound(sound_name, _position = null):
	var audio_player = _audio_player_prefab.instance()
	self.add_child(audio_player)
	audio_player.play_sound(sound_name, _position)

func _rpc_input_release(method, args, fallback, fallback_args):
	if Input.is_action_pressed(fallback):
		_rpc_master_and_local(method, fallback_args)
	else:
		_rpc_master_and_local(method, args)

func _rpc_master_and_local(method, args):
	rpc_id(1, method, args)
	if not get_tree().is_network_server():
		call(method, args)

master func _on_move_status_change(status):
	var id = get_tree().get_rpc_sender_id()
	set_server_current_frame_data(id, status | 0x8, 0xffff0)

master func _on_trun_status_change(status):
	var id = get_tree().get_rpc_sender_id()
	set_server_current_frame_data(id, (status | 0x8) << 4, 0xfff0f)

master func _on_fire_status_change(status):
	var id = get_tree().get_rpc_sender_id()
	set_server_current_frame_data(id, (status | 0x8) << 8, 0xff0ff)

master func _on_turrent_turn_status_change(status):
	var id = get_tree().get_rpc_sender_id()
	set_server_current_frame_data(id, (status | 0x8) << 12, 0xf0fff)

master func _on_turrent_pitch_status_change(status):
	var id = get_tree().get_rpc_sender_id()
	set_server_current_frame_data(id, (status | 0x8) << 16, 0x0ffff)

remotesync func _on_net_frame(frame):
	_net_frame_recv_count += 1
	_net_frames.push_back(frame)
	#print("_on_net_frame(%d):" % _net_frame_recv_count, str(frame))
	
