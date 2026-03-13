extends Node

var logfile: FileAccess

func _ready() -> void:
	print(Engine.get_license_text())
	
	var timestamp = Time.get_datetime_dict_from_system()
	
	timestamp = str(timestamp["year"]) + "-" + str(timestamp["month"]) + "-" + str(timestamp["day"]) + "-" + str(timestamp["hour"]) + "-" + str(timestamp["minute"]) + "-" + str(timestamp["second"])
	
	if DirAccess.open("user://program-logs"):
		logfile = FileAccess.open("user://program-logs/" + timestamp + ".txt", FileAccess.WRITE)
	else:
		DirAccess.make_dir_absolute("user://program-logs")
		logfile = FileAccess.open("user://program-logs/" + timestamp + ".txt", FileAccess.WRITE)

func log_info(text):
	var timestamp = Time.get_datetime_dict_from_system()
	
	timestamp = str(timestamp["hour"]) + ":" + str(timestamp["minute"]) + ":" + str(timestamp["second"])
	print("[" + timestamp + "] " + text)
	logfile.store_string("[" + timestamp + "] " + text + "\n")
