extends CanvasLayer

signal sig_loading_done()

var smooth_speed = 100.0

var _target_value = 0.0

func _ready():
	hide()


func _process(delta):
	var value = smooth_speed * delta + $Control/ProgressBar.value
	$Control/ProgressBar.value = clamp(value, 0.0, _target_value)
	if value >= _target_value:
		set_process(false)
	if value >= 100.0:
		emit_signal("sig_loading_done")


func show():
	$Control.show()
	set_progress(0)


func hide():
	$Control.hide()
	set_process(false)


func set_progress(value:float):
	_target_value = clamp(value, 0.0, 1.0) * 100.0
	if $Control/ProgressBar.value > _target_value:
		$Control/ProgressBar.value = _target_value
	set_process(true)
