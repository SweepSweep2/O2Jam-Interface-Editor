extends PopupMenu

func _on_id_pressed(id: int) -> void:
	if id == 0:
		Program.open_file_popup()
	elif id == 1:
		File.save()
