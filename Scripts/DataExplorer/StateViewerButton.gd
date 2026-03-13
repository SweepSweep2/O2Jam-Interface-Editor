extends Button

func _on_pressed() -> void:
	for child in get_tree().current_scene.get_node("StatePreview").get_children():
		child.queue_free()
	
	File.show_state(text)
