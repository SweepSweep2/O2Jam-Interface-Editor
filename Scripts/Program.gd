extends Node

var open_file := load("res://Objects/OpenFile.tscn")

func open_file_popup():
	var open_file_instantiated: FileDialog = open_file.instantiate()
	
	get_tree().current_scene.add_child(open_file_instantiated)

func _ready():
	DiscordRPC.app_id = 1477696973695090769
	DiscordRPC.details = "Home"
	DiscordRPC.large_image = "icon_base"
	DiscordRPC.large_image_text = "O2Jam Interface Editor"
	
	DiscordRPC.start_timestamp = int(Time.get_unix_time_from_system())
	DiscordRPC.refresh()
