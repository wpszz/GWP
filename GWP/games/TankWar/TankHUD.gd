extends CanvasLayer

var world = null

var my_tank = null

func _ready():
	my_tank = world.get_my_tank()
	Utility.connect_ex(my_tank, "sig_tank_fire", self, "_on_tank_fire")
	Utility.connect_ex(my_tank, "sig_tank_damaged", self, "_on_tank_damage")
	update_hud(my_tank)
	update_reload(my_tank)

func update_hud(tank):
	$Armor.text = "%d/%d" % [FPMath.to_float(tank.fp_data.armor_cur), FPMath.to_float(tank.fp_data.armor_max)]
	$Ammo.text = "%d/%d" % [FPMath.to_float(tank.fp_data.ammo_cur), FPMath.to_float(tank.fp_data.ammo_max)]

func update_reload(tank):
	var cur = FPMath.to_float(world.fp_data.net_total_time)
	var last = FPMath.to_float(tank.fp_data.fire_last_time)
	var interval = FPMath.to_float(tank.fp_data.fire_interval)
	var pass_time = cur - last
	if pass_time < interval:
		$Reload.text = "%.1fsec" % (interval - pass_time)
	else:
		$Reload.text = ""

func _on_tank_fire(tank):
	if tank != my_tank:
		return
	update_hud(tank)
	
func _on_tank_damage(tank, _value):
	if tank != my_tank:
		return
	update_hud(tank)

func _process(_delta):
	update_reload(my_tank)

func _on_Leave_pressed():
	NetGame.call_deferred("leave_game")
