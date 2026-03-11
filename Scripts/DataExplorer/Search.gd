extends LineEdit

func _on_text_changed(new_text: String) -> void:
	for node in get_parent().get_node("ScrollContainer").get_node("VBoxContainer").get_children():
		if not new_text.to_lower() in node.name.to_lower():
			node.visible = false
		else:
			node.visible = true
		
		if new_text == "":
			node.visible = true
