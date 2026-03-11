extends Panel

func _on_select_data_explorer_pressed() -> void:
	$ScrollContainer.visible = true
	$StateViewer.visible = false

func _on_select_state_viewer_pressed() -> void:
	$ScrollContainer.visible = false
	$StateViewer.visible = true
