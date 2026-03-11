extends Control

func _on_show_object_names_toggled(toggled_on: bool) -> void:
	for state_object in $StatePreview.get_children():
		state_object.get_node("ObjectName").visible = toggled_on
