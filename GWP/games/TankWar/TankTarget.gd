extends Sprite


func _ready():
	$AnimationPlayer.play("Idle")

func get_path_target():
	return self.position + $Path.points[1]

func set_path_target(pos:Vector2):
	$Path.points[1] = pos - self.position
