extends Node

static func logxy(x,y):
	return log(y) / log(x)

static func test():
	print("--- FPMath test started ---")
	var ms_start = OS.get_ticks_msec()
	var FPMath_fun_cache = {}
	var fpmath_test_output = File.new()
	fpmath_test_output.open("../Temp/fpmath_test_fail.txt", File.WRITE)
	var fpmath_test_fail = 0
	var fpmath_test_max_err = 0
	var fpmath_test_max_err_per = 0
	var test_range = 50
	for ix in range(-test_range, test_range):
		for iy in range(-test_range, test_range):
			var e = 0.05
			var ee = 0.0005
			var scale = 17 # 0.01 0.1 1 17 773 2137 18443
			var rx = (ix + 0.5) / 17.0 * scale
			var ry = (iy + 0.5) / 17.0 * scale
			var rz = ix / float(test_range) #[-1, 1]
			var rw = iy / float(test_range) #[-1, 1]
			var rp = rz * PI * 2 #[-2pi, 2pi]
			var rq = rz * PI / 2 * (1 - e) #[-pi/2 + e, pi/2 - e]
			var rr = rw * 5; #[-5, 5]
			var rs = (rz * 0.5 + 0.5) * scale + e #[e, scale + e]
			var rt = (rw * 0.5 + 0.5) * scale + e #[e, scale + e]
			var ru = (rz * 0.5 + 0.5) + ee #[ee, 1 + ee]
			var rv = (rw + 2) * scale #[1, scale]
			var fpx = FPMath.from_number(rx)
			var fpy = FPMath.from_number(ry)
			var fpz = FPMath.from_number(rz)
			var fpw = FPMath.from_number(rw)
			var fpp = FPMath.from_number(rp)
			var fpq = FPMath.from_number(rq)
			var fpr = FPMath.from_number(rr)
			var fps = FPMath.from_number(rs)
			var fpt = FPMath.from_number(rt)
			var fpu = FPMath.from_number(ru)
			var fpv = FPMath.from_number(rv)
			var abs_fpx = FPMath.abs(fpx)
			var unit_tests = [
				["from_number",	rx,				[rx],			0.00001],
				["add",			rx + ry,		[fpx, fpy],		0.0001],
				["sub",			rx - ry,		[fpx, fpy],		0.0001],
				["mul",			rx * ry,		[fpx, fpy],		0.005],
				["div",			rx / ry,		[fpx, fpy],		0.001],
				["floor",		floor(rx),		[fpx],			0],
				["ceil",		ceil(rx),		[fpx],			0],
				["abs",			abs(rx),		[fpx],			0.0001],
				["sqrt",		sqrt(rx),		[abs_fpx],		0.0001],
				["sin",			sin(rx),		[fpx],			0.0005],
				["cos",			cos(rp),		[fpp],			0.0005],
				["tan",			tan(rq),		[fpq],			0.003],
				["atan2",		atan2(rz, rw),	[fpz, fpw],		0.0005],
				["acos",		acos(rw),		[fpw],			0.0005],
				["log",			logxy(rs, rt),	[fps, fpt],		0.0005],
				["pow",			pow(rs, rr),	[fps, fpr],		0.0005],
				["pow",			pow(ru, rv),	[fpu, fpv],		0.0005],
			]
			for i in unit_tests.size():
				var unit_test = unit_tests[i]
				var fun_name = unit_test[0]
				var expected = unit_test[1]
				var args = unit_test[2]
				var fun = null
				if FPMath_fun_cache.has(fun_name):
					fun = FPMath_fun_cache[fun_name]
				else:
					fun = funcref(FPMath, fun_name)
					FPMath_fun_cache[fun_name] = fun
				var actual = FPMath.to_float(fun.call_funcv(args))
				var precision = unit_test[3]
				var err = abs(expected - actual)
				var err_per = 1;
				if expected != 0:
					err_per = err / abs(expected)
				if err > precision && err_per > precision:
					var args_str = ""
					for j in args.size():
						if j > 0:
							args_str += ", "
						args_str += "%d/%f" % [args[j], FPMath.to_float(args[j])]
					fpmath_test_output.store_line("%s(%s)=[%f, %f], err=%f, err_per=%f%%" % [
						fun_name, args_str, expected, actual, err, err_per * 100
					])
					fpmath_test_fail += 1
					fpmath_test_max_err = max(fpmath_test_max_err, err)
					if expected != 0:
						fpmath_test_max_err_per = max(fpmath_test_max_err_per, err_per)
	print("fpmath test(%s) failed count: %d" % [fpmath_test_output.get_path(), fpmath_test_fail])
	fpmath_test_output.store_line("test failed count: %d" % fpmath_test_fail);
	fpmath_test_output.store_line("test failed max error: %f" % fpmath_test_max_err);
	fpmath_test_output.store_line("test failed max error percent: %f%%" % (fpmath_test_max_err_per * 100));
	fpmath_test_output.close()
	print("--- FPMath test stopped(cost: %fms) --- " % (OS.get_ticks_msec() - ms_start))

static func generate_luts():
	generate_sin_lut()
	generate_atan_lut()

static func generate_sin_lut(size = 9000):
	var lut = File.new()
	lut.open("../NativePlugins/FPMath/src/FPMathSinLut.h", File.WRITE)
	lut.store_line("#ifndef __FP_MATH_SIN_LUT_H__")
	lut.store_line("#define __FP_MATH_SIN_LUT_H__")
	lut.store_line("")
	lut.store_line("static const int32_t FP_SIN_LUT_SIZE = %d;" % size)
	lut.store_line("static const int32_t FP_SIN_LUT[%d] = {" % (size + 1))
	var half_pi = PI / 2
	for i in size:
		var rad = i * half_pi / size
		var real = sin(rad)
		var fd = FPMath.from_number(real)
		if i % 8 == 0:
			lut.store_string("\n\t")
		lut.store_string("%d, " % fd)
	lut.store_string("%d" % FPMath.from_number(1))
	lut.store_line("")
	lut.store_line("};")
	lut.store_line("#endif")
	lut.close()

static func generate_atan_lut(size = 4500):
	var lut = File.new()
	lut.open("../NativePlugins/FPMath/src/FPMathAtanLut.h", File.WRITE)
	lut.store_line("#ifndef __FP_MATH_ATAN_LUT_H__")
	lut.store_line("#define __FP_MATH_ATAN_LUT_H__")
	lut.store_line("")
	lut.store_line("static const int32_t FP_ATAN_LUT_SIZE = %d;" % size)
	lut.store_line("static const int32_t FP_ATAN_LUT[%d] = {" % (size + 1))
	var pi_over_4 = PI / 4
	for i in size:
		var z = float(i) / size
		var real = atan(z)
		var fd = FPMath.from_number(real)
		if i % 8 == 0:
			lut.store_string("\n\t")
		lut.store_string("%d, " % fd)
	lut.store_string("%d" % FPMath.from_number(pi_over_4))
	lut.store_line("")
	lut.store_line("};")
	lut.store_line("#endif")
	lut.close()
