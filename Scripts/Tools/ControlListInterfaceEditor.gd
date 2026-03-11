extends Window

func _ready() -> void:
	$TextEdit.text = File.files["ControlList_Interface.txt"]["data"].get_string_from_ascii()

func _on_close_requested() -> void:
	queue_free()

func _on_text_edit_text_changed() -> void:
	File.parse_control_list_interface(File.to_iso88591($TextEdit.text))
	File.files["ControlList_Interface.txt"]["data"] = File.save_control_list_interface(File.parsed_control_list_interface)
