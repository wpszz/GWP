extends Spatial

var _material = preload("res://models/Genesis2Female/Genesis2Female.material")

var _model : MeshInstance = null

var faceto_speed = PI * 2 # 360 degree per-second
var _faceto_progress = 1.0
var _faceto_step = 0.0
var _faceto_from : Quat
var _faceto_to : Quat

var moveto_speed = 3.0
var _moveto_progress = 1.0
var _moveto_step = 0.0
var _moveto_from : Vector3
var _moveto_to : Vector3

func _ready():
	_model = $Genesis2Female/Skeleton/Genesis2FemaleShape
	_model.material_override = _material.duplicate(true)	

func _process(delta):
	if _faceto_progress < 1.0:
		_faceto_progress += delta * _faceto_step
		_faceto_progress = min(_faceto_progress, 1.0);
		self.transform.basis = _faceto_from.slerp(_faceto_to, _faceto_progress)
		
	if _moveto_progress < 1.0:
		_moveto_progress += delta * _moveto_step
		_moveto_progress = min(_moveto_progress, 1.0);
		self.transform.origin = _moveto_from.linear_interpolate(_moveto_to, _moveto_progress)

func delaycall(delay:float, fun:FuncRef, args):
	yield(get_tree().create_timer(delay), "timeout")
	fun.call_func(args)

# only rotated around Y-axis
func faceto(target:Vector3):
	target.y = self.transform.origin.y
	var z = (target - self.transform.origin).normalized()
	if z == Vector3.ZERO:
		return
	var angle = acos(self.transform.basis.z.dot(z))
	if angle < 0.000001:
		_faceto_progress = 1.0
		return
	var y = Vector3(0, 1, 0)
	var x = y.cross(z)
	_faceto_from = self.transform.basis.get_rotation_quat()
	_faceto_to = Basis(x, y, z).get_rotation_quat()
	_faceto_progress = 0
	_faceto_step = faceto_speed / angle

func moveto(target:Vector3):
	var dis = self.transform.origin.distance_to(target)
	if dis < 0.000001:
		_moveto_progress = 1.0
		return	
	_moveto_from = self.transform.origin
	_moveto_to = target
	_moveto_progress = 0
	_moveto_step = moveto_speed / dis

func attack():
	$AnimationTree["parameters/oneshot_attack/active"] = true

func attacked():
	$AnimationTree["parameters/oneshot_attacked/active"] = true
