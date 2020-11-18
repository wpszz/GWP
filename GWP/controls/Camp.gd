extends Control

var seat_list

func _ready():
	seat_list = $SeatList

func set_title(title):
	$Title/Label.text = title
