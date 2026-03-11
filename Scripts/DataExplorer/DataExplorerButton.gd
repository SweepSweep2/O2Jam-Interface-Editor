extends Button

func _on_pressed() -> void:
	if text == "abusedata.ojs":
		DiscordRPC.details = "Viewing abusedata.ojs"
		DiscordRPC.refresh()
		
		var new_abuse_data_viewer: Window = load("res://Tools/AbuseDataViewer.tscn").instantiate()
		get_tree().current_scene.add_child(new_abuse_data_viewer)
	elif text == "ControlList_Interface.txt":
		DiscordRPC.details = "Editing ControlList_Interface.txt"
		DiscordRPC.refresh()
		
		var new_cli_editor: Window = load("res://Tools/ControlListInterfaceEditor.tscn").instantiate()
		get_tree().current_scene.add_child(new_cli_editor)
	elif text.ends_with(".bnd"):
		DiscordRPC.details = "Editing " + text
		DiscordRPC.refresh()
		
		var new_bnd_viewer: Window = load("res://Tools/BNDViewer.tscn").instantiate()
		new_bnd_viewer.file = text
		
		get_tree().current_scene.add_child(new_bnd_viewer)
	else:
		if File.files[text]["data"] == PackedByteArray():
			File.file.seek(File.files[text]["offset"])
			File.files[text]["data"] = File.file.get_buffer(File.files[text]["size"])
			File.parse_ojs(File.files[text]["data"], text)
		
		var new_ojs_viewer: Window = load("res://Tools/OJSViewer.tscn").instantiate()
		new_ojs_viewer.file_name = text
		get_tree().current_scene.add_child(new_ojs_viewer)
	
