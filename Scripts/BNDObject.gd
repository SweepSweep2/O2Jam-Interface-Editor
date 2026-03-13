extends Control

var object_id
var selected = false

var x
var y
var end_x
var end_y

signal clicked(id: int, x: int, y: int, width: int, height: int)

func _ready() -> void:
	$ObjectName.text = "Object " + str(object_id)
	
	size = $ObjectName.size

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			emit_signal("clicked", object_id, x, y, end_x, end_y)
