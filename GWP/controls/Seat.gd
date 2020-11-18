extends Panel

var node_name : Button
var node_color : ColorRect
var node_status : Label
var node_swap : Button

func _ready():
	node_name = $Name
	node_color = $Color
	node_status = $Status
	node_swap = $Swap


func set_data(_name, _color, status, name_disable = false, swap_disable = false):
	node_name.text = _name
	node_color.color = _color
	node_status.text = status
	node_name.disabled = name_disable
	node_swap.disabled = swap_disable
