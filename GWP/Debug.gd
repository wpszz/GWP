extends Node

# custom signals
signal sig_alert(caption, what)

func verbose(what):
	print(what)


func warning(what):
	print(what)


func error(what):
	printerr(what)

func alert(what, caption = "alert"):
	# attach to external ui
	emit_signal("sig_alert", what, caption)
