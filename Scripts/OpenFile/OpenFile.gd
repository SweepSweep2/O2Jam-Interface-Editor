extends FileDialog

func _on_file_selected(path: String) -> void:
	File.parse(path)
