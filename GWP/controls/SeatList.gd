extends Control

#class_name SeatList, "res://editor/icons/icon_control.svg"

signal sig_name_pressed(index)
signal sig_swap_pressed(index)

export var count = 1

var seats = []

func _ready():
	var _count = count
	count = 1
	seats.append($VBoxContainer/Seat_0)
	Utility.connect_ex(seats[0].node_name, "pressed", self, "_on_name_pressed", 0)
	Utility.connect_ex(seats[0].node_swap, "pressed", self, "_on_swap_pressed", 0)
	set_count(_count)


func set_count(_count):
	if _count > count:
		for i in range(count, _count):
			if i >= seats.size():
				seats.append(seats[0].duplicate())
				seats[i].name = "Seat_" + str(i)
				$VBoxContainer.add_child(seats[i])
				Utility.connect_ex(seats[i].node_name, "pressed", self, "_on_name_pressed", i)
				Utility.connect_ex(seats[i].node_swap, "pressed", self, "_on_swap_pressed", i)
			else:
				seats[i].visible = true
	else:
		for i in range(_count, count):
			seats[i].visible = false
	count = _count


func _on_name_pressed(index):
	emit_signal("sig_name_pressed", index)


func _on_swap_pressed(index):
	emit_signal("sig_swap_pressed", index)
