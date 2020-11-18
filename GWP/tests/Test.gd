extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	#$Player.attacked()
	#print(.material_override)
		
	$Player.faceto($Camera.transform.origin)
	$Player2.faceto($Player.transform.origin)
	$Player3.faceto($Player.transform.origin)
	$Player4.faceto($Player.transform.origin)
	$Player5.faceto($Player.transform.origin)
	
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(_delta):
	if Input.is_action_just_pressed("attack"):
		$Player.attack()
		var advance = $Player.transform.origin + $Player.transform.basis.z * 0.5
		#$Player.moveto(advance)
		$Player.delaycall(0.6, funcref($Player, "moveto"), advance)
	if Input.is_action_pressed("attacked"):
		$Player.attacked()
			
