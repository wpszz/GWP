extends Node

var _fplib = preload("res://bin/FPMath/LibFPMath.gdns").new()

var one setget , _get_one
func _get_one():
	return _fplib.one

var pi setget , _get_pi
func _get_pi():
	return _fplib.pi

var epsilon setget , _get_epsilon
func _get_epsilon():
	return 1

func from_number(number)->int:
	return _fplib.to_fixed(number)

func from_vec2(vec2:Vector2)->Array:
	return [_fplib.to_fixed(vec2.x), _fplib.to_fixed(vec2.y)]

func from_transform2D(pos:Vector2, angle:float, scale:Vector2 = Vector2.ONE)->Array:
	var fp_rad = _fplib.deg2rad(_fplib.to_fixed(angle))
	var fp_sx = _fplib.to_fixed(scale.x)
	var fp_sy = _fplib.to_fixed(scale.y)
	var fp_sin = _fplib.sin(fp_rad)
	var fp_cos = _fplib.cos(fp_rad)
	# 2x3 matrix(column major)
	return [
		[_fplib.mul(fp_cos, fp_sx), _fplib.mul(-fp_sin, fp_sy), _fplib.to_fixed(pos.x)],
		[_fplib.mul(fp_sin, fp_sx), _fplib.mul(fp_cos, fp_sy),  _fplib.to_fixed(pos.y)]
	]

func to_float(fp:int)->float:
	return _fplib.to_float(fp)

func to_vec2(fp:Array)->Vector2:
	return Vector2(_fplib.to_float(fp[0]), _fplib.to_float(fp[1]))

func to_transform2D(fp:Array)->Transform2D:
	var t = Transform2D()
	t.x.x = _fplib.to_float(fp[0][0])
	t.x.y = _fplib.to_float(fp[1][0])
	t.y.x = _fplib.to_float(fp[0][1])
	t.y.y = _fplib.to_float(fp[1][1])
	t.origin.x = _fplib.to_float(fp[0][2])
	t.origin.y = _fplib.to_float(fp[1][2])
	return t
	#return Transform2D(xx, xy, yx, yy, ox, oy)

func add(fpa:int, fpb:int)->int:
	return _fplib.add(fpa, fpb)

func sub(fpa:int, fpb:int)->int:
	return _fplib.sub(fpa, fpb)

func mul(fpa:int, fpb:int)->int:
	return _fplib.mul(fpa, fpb)

func div(fpa:int, fpb:int)->int:
	return _fplib.div(fpa, fpb)

func floor(fpa:int)->int:
	return _fplib.floor(fpa)

func ceil(fpa:int)->int:
	return _fplib.ceil(fpa)

func abs(fpa:int)->int:
	return _fplib.abs(fpa)

func sqrt(fpa:int)->int:
	return _fplib.sqrt(fpa)

func sin(fpa:int)->int:
	return _fplib.sin(fpa)

func cos(fpa:int)->int:
	return _fplib.cos(fpa)

func tan(fpa:int)->int:
	return _fplib.tan(fpa)

func atan(fpa:int)->int:
	return _fplib.atan(fpa)

func atan2(fpy:int, fpx:int)->int:
	return _fplib.atan2(fpy, fpx)

func acos(fpa:int)->int:
	return _fplib.acos(fpa)

func pow(fpa:int, fpb:int)->int:
	return _fplib.pow(fpa, fpb)

func log(fpa:int, fpb:int)->int:
	return _fplib.log(fpa, fpb)

func deg2rad(fpa:int)->int:
	return _fplib.deg2rad(fpa)

func rad2deg(fpa:int)->int:
	return _fplib.rad2deg(fpa)

var _fp_deg360 = _fplib.to_fixed(360)
func deg_normalize(fpa:int)->int:
	return fpa % _fp_deg360

func rad_normalize(fpa:int)->int:
	return fpa % (self.pi * 2)

func clamp(fpa:int, fpfrom:int, fpto:int)->int:
	if fpa <= fpfrom:
		return fpfrom
	if fpa >= fpto:
		return fpto
	return fpa

func lerp(fpfrom:int, fpto:int, fpt:int)->int:
	return _fplib.add(fpfrom, _fplib.mul(_fplib.sub(fpto, fpfrom), fpt))

func vec2_add(fpa:Array, fpb:Array, fpout = null)->Array:
	fpout = fpout if fpout != null else [0, 0]
	fpout[0] = _fplib.add(fpa[0], fpb[0])
	fpout[1] = _fplib.add(fpa[1], fpb[1])
	return fpout

func vec2_sub(fpa:Array, fpb:Array, fpout = null)->Array:
	fpout = fpout if fpout != null else [0, 0]
	fpout[0] = _fplib.sub(fpa[0], fpb[0])
	fpout[1] = _fplib.sub(fpa[1], fpb[1])
	return fpout

func vec2_scale(fpa:Array, fpb:int, fpout = null)->Array:
	fpout = fpout if fpout != null else [0, 0]
	fpout[0] = _fplib.mul(fpa[0], fpb)
	fpout[1] = _fplib.mul(fpa[1], fpb)
	return fpout

func vec2_dot(fpa:Array, fpb:Array)->int:
	return _fplib.add(_fplib.mul(fpa[0], fpb[0]), _fplib.mul(fpa[1], fpb[1]))

func vec2_distance(fpa:Array, fpb:Array)->int:
	var fpc = vec2_sub(fpa, fpb)
	var fpsquaue = vec2_dot(fpc, fpc)
	return _fplib.sqrt(fpsquaue)

func vec2_normalize(fpa:Array)->Array:
	var dis = _fplib.sqrt(vec2_dot(fpa, fpa))
	if dis <= 1:
		return [0, 0]
	else:
		return [_fplib.div(fpa[0], dis), _fplib.div(fpa[1], dis)]

func vec2_cross_magnitude(p1:Array, p2:Array, p3:Array)->int:
	# signed magnitude of cross(p2 - p1, p3 - p1)
	# ret = p1.x * p2.y + p2.x * p3.y + p3.x * p1.y - p1.x * p3.y - p2.x * p1.y - p3.x * p2.y
	var p1x2y = _fplib.mul(p1[0], p2[1])
	var p2x3y = _fplib.mul(p2[0], p3[1])
	var p3x1y = _fplib.mul(p3[0], p1[1])
	var p1x3y = _fplib.mul(p1[0], p3[1])
	var p2x1y = _fplib.mul(p2[0], p1[1])
	var p3x2y = _fplib.mul(p3[0], p2[1])
	#return p1x2y + p2x3y + p3x1y - p1x3y - p2x1y - p3x2y
	return _fplib.sub(_fplib.sub(_fplib.sub(_fplib.add(_fplib.add(p1x2y, p2x3y), p3x1y), p1x3y), p2x1y), p3x2y)

func vec2_is_clockwise(p1:Array, p2:Array, p3:Array)->bool:
	# check cross sign
	return vec2_cross_magnitude(p1, p2, p3) < 0

func vec2_is_clockwise_margin(p1:Array, p2:Array, p3:Array)->bool:
	# check cross sign
	return vec2_cross_magnitude(p1, p2, p3) <= self.epsilon;

func aabb_collide(fpa:Array, fpb:Array)->bool:
	var a_min = fpa[0]
	var a_max = fpa[1]
	var b_min = fpb[0]
	var b_max = fpb[1]
	if a_min[0] > b_max[0] or a_max[0] < b_min[0]:
		return false
	if a_min[1] > b_max[1] or a_max[1] < b_min[1]:
		return false
	return true

func matrix23(fppos:Array, fpangle:int, fpscale:Array = [self.one, self.one])->Array:
	var fp_rad = _fplib.deg2rad(fpangle)
	var fp_sx = fpscale[0]
	var fp_sy = fpscale[1]
	var fp_sin = _fplib.sin(fp_rad)
	var fp_cos = _fplib.cos(fp_rad)
	# 2x3 matrix(column major)
	return [
		[_fplib.mul(fp_cos, fp_sx), _fplib.mul(-fp_sin, fp_sy), fppos[0]],
		[_fplib.mul(fp_sin, fp_sx), _fplib.mul(fp_cos, fp_sy),  fppos[1]]
	]

func matrix23_xform(fpmat:Array, fpv:Array)->Array:
	return [
		_fplib.add(_fplib.add(_fplib.mul(fpmat[0][0], fpv[0]), _fplib.mul(fpmat[0][1], fpv[1])), fpmat[0][2]),
		_fplib.add(_fplib.add(_fplib.mul(fpmat[1][0], fpv[0]), _fplib.mul(fpmat[1][1], fpv[1])), fpmat[1][2]),
	]

func matrix23_mul(fpa:Array, fpb:Array)->Array:
	return [
		[
			_fplib.add(_fplib.mul(fpa[0][0], fpb[0][0]), _fplib.mul(fpa[0][1], fpb[1][0])),
			_fplib.add(_fplib.mul(fpa[0][0], fpb[0][1]), _fplib.mul(fpa[0][1], fpb[1][1])),
			_fplib.add(_fplib.add(_fplib.mul(fpa[0][0], fpb[0][2]), _fplib.mul(fpa[0][1], fpb[1][2])), fpa[0][2]),
		],
		[
			_fplib.add(_fplib.mul(fpa[1][0], fpb[0][0]), _fplib.mul(fpa[1][1], fpb[1][0])),
			_fplib.add(_fplib.mul(fpa[1][0], fpb[0][1]), _fplib.mul(fpa[1][1], fpb[1][1])),
			_fplib.add(_fplib.add(_fplib.mul(fpa[1][0], fpb[0][2]), _fplib.mul(fpa[1][1], fpb[1][2])), fpa[1][2]),
		],
	]
