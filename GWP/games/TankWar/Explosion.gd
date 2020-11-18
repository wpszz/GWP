extends Sprite

func _ready():
	$AnimationPlayer.play("explosion")

func done():
	queue_free()
