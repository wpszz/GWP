extends Control


func _ready():
	print("user data dir: ", OS.get_user_data_dir())
	
	_test()
	
	Utility.connect_ex(Debug, "sig_alert", self, "_on_alert")

	SceneMgr.load_hall()

func _on_alert(what, caption):
	$CanvasLayer/Msgbox.window_title = caption
	$CanvasLayer/Msgbox.dialog_text = what
	#$CanvasLayer/Msgbox.add_button("left", false, "click left")
	#$CanvasLayer/Msgbox.add_button("right", true, "click right")
	#$CanvasLayer/Msgbox.add_cancel("cancel")
	$CanvasLayer/Msgbox.popup_centered_minsize()


func _on_Msgbox_confirmed():
	pass # Replace with function body.
	

func _test():
	print("--- Main test started ---")
	
	#preload("res://tests/UnitTestFPMath.gd").test()
	#preload("res://tests/UnitTestFPMath.gd").generate_luts()

	print("--- Main test stopped ---")
