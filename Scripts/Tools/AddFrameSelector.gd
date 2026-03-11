extends Window

var open_file := load("res://Objects/AddFrameFilePicker.tscn")

func _on_close_requested() -> void:
	queue_free()

func _on_button_pressed() -> void:
	queue_free()
