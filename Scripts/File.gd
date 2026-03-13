extends Node

var file_type := 0
var file_count := 0

var files := {}
var lowercase_files := {}
var ojs_files := {}
var ojs_keys_lower := {}
var parsed_control_list_interface := {}

var swears := []

var file: FileAccess
var file_path: String
var data_explorer_button := load("res://Objects/DataExplorerButton.tscn")
var state_object := load("res://Objects/StateObject.tscn")
var state_viewer_button := load("res://Objects/StateViewerButton.tscn")

var already_loaded = false

func show_state(state: String):
	GlobalLogger.log_info("Showing state " + state + "...")
	
	var file_name := ""
	var lowercase_file_key := ""
	var i := 0
	
	var names := []
	var file_names := []
	
	for key in parsed_control_list_interface[state]:
		var value = parsed_control_list_interface[state][key]
		
		if not key.begins_with("set_"):
			if key != "values" and key != "BOUND":
				if len(value["values"]) > 1:
					file_name = value["values"][1].replace("\"", "").replace(" ", "")
					
					if file_name.to_lower() in lowercase_files and not file_name.to_lower().begins_with("o2_sbs"):
						lowercase_file_key = lowercase_files[file_name.to_lower()]
						
						if ojs_files[ojs_keys_lower[file_name.to_lower()]]["frames"] == []:
							file.seek(files[lowercase_file_key]["offset"])
							files[lowercase_file_key]["data"] = file.get_buffer(files[lowercase_file_key]["size"])
							parse_ojs(files[lowercase_file_key]["data"], file_name)
					else:
						file_name = ""
				else:
					file_name = ""
				
				names.append(key)
				file_names.append(file_name)
		else:
			for object in parsed_control_list_interface[state][key]:
				if object != "values":
					if len(parsed_control_list_interface[state][key][object]["values"]) > 1:
						if file_name.to_lower() in lowercase_files:
							lowercase_file_key = lowercase_files[file_name.to_lower()]
							
							names.append(object)
							file_names.append(file_name)
							
							continue
						
						if file_name.to_lower() == "":
							names.append(object)
							file_names.append(file_name)
							
							continue
						
						if ojs_files[ojs_keys_lower[file_name.to_lower()]]["frames"] == []:
							if file_name.to_lower() in lowercase_files and not file_name.to_lower().begins_with("o2_sbs"):
								file.seek(files[lowercase_file_key]["offset"])
								files[lowercase_file_key]["data"] = file.get_buffer(files[lowercase_file_key]["size"])
								parse_ojs(files[lowercase_file_key]["data"], file_name)
							else:
								file_name = ""
					else:
						file_name = ""
					
					names.append(object)
					file_names.append(file_name)
	
	var dialog_background := false
	
	if parsed_control_list_interface[state]["values"][0].to_lower() == "0x00":
		GlobalLogger.log_info("State is empty! Skipping...")
		return
	
	if len(parsed_control_list_interface[state]["BOUND"]["values"]) == 0:
		GlobalLogger.log_info("No bound file! Skipping...")
		return
	
	var there := true
	
	if not parsed_control_list_interface[state]["BOUND"]["values"][0].replace("\"", "").to_lower() in lowercase_files:
		GlobalLogger.log_info("No bound file found in interface file! Skipping...")
		there = false
	
	if there:
		for object in files[lowercase_files[parsed_control_list_interface[state]["BOUND"]["values"][0].replace("\"", "").to_lower()]]["data"]["objects"]:
			if i == 0:
				i += 1
				
				if state.begins_with("DIALOG_"):
					dialog_background = true
			
			if i == len(names):
				return
			
			var add_x := 0.0
			var add_y := 0.0
			
			var state_object_instantiated: Control = state_object.instantiate()
			state_object_instantiated.get_node("ObjectFrames").sprite_frames = SpriteFrames.new()
			
			state_object_instantiated.name = names[i]
			
			var frames := []
			
			if file_names[i] != "":
				for frame in ojs_files[ojs_keys_lower[file_names[i].to_lower()]]["frames"]:
					var img := Image.new()
					img.load_bmp_from_buffer(frame["data"])
					
					frames.append(ImageTexture.create_from_image(img))
			else:
				frames = []
			
			state_object_instantiated.get_node("ObjectFrames").sprite_frames.add_animation(names[i])
			
			for frame in frames:
				state_object_instantiated.get_node("ObjectFrames").sprite_frames.add_frame(names[i], frame)
			
			state_object_instantiated.text = names[i]
			
			if not get_tree().current_scene.get_node("ShowObjectNames").button_pressed:
				state_object_instantiated.get_node("ObjectName").visible = false
			
			get_tree().current_scene.get_node("StatePreview").add_child(state_object_instantiated)
			
			state_object_instantiated.get_node("ObjectFrames").play(names[i])
			
			state_object_instantiated.get_node("ObjectName").position.x -= add_x
			state_object_instantiated.get_node("ObjectName").position.y -= add_y
			
			# dialog boxes have their positions centered in the screen while the buttons do not, this fixes that issue
			if not dialog_background:
				state_object_instantiated.position = Vector2(object["start_x"] + add_x, object["start_y"] + add_y)
			else:
				state_object_instantiated.position = Vector2(add_x, add_y)
				dialog_background = false
			
			i += 1
	
	GlobalLogger.log_info("Successfully showed state " + state + "!")

func parse_bnd(bnd_file: PackedByteArray):
	var object_count := bnd_file.decode_u16(4)
	
	var start_x := 0
	var start_y := 0
	var end_x := 0
	var end_y := 0
	
	var objects := []
	
	@warning_ignore("integer_division")
	for i in range((len(bnd_file) - 6) / 16):
		start_x = bnd_file.decode_u32((i * 16) + 6)
		start_y = bnd_file.decode_u32((i * 16) + 10)
		end_x = bnd_file.decode_u32((i * 16) + 14)
		end_y = bnd_file.decode_u32((i * 16) + 18)
		
		objects.append(
			{
				"start_x": start_x,
				"start_y": start_y,
				"end_x": end_x,
				"end_y": end_y
			}
		)
	
	var extra_data := PackedByteArray()
	
	@warning_ignore("integer_division")
	for i in range((floor((len(bnd_file) - 6) / 16) * 16), len(bnd_file) - 6):
		extra_data.append(bnd_file[i])
	
	@warning_ignore("integer_division")
	if (len(bnd_file) - 6) - (floor((len(bnd_file) - 6) / 16) * 16) != 0:
		objects.append({
			"extra_data": extra_data
		})
	
	return {
		"object_count": object_count,
		"objects": objects
	}

func parse_abusedata(abusedata):
	File.swears = []
	
	var temp := ""
	var i := 0
	
	while i != len(abusedata):
		if abusedata[i] == 13:
			i += 2
			swears.append(temp)
			temp = ""
		
		temp += char(abusedata[i])
		
		i += 1
	
	swears.append(temp)

func to_iso88591(string):
	var return_value := PackedByteArray()
	
	for byte in string:
		return_value.append(ord(byte))
	
	return return_value

func save():
	GlobalLogger.log_info("Saving...")
	var file_type_resized := PackedByteArray([0, 0, 0, 0])
	file_type_resized.encode_u32(0, file_type)
	
	var file_count_resized := PackedByteArray([0, 0, 0, 0])
	file_count_resized.encode_u32(0, file_count)
	
	var file_to_save := file_type_resized + file_count_resized + PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0])
	var file_index := PackedByteArray()
	
	var file_name := PackedByteArray()
	var resized_file_size := PackedByteArray()
	var current_offset := 16
	var resized_current_offset := PackedByteArray()
	
	var bnd_file := PackedByteArray()
	var bnd_obj_count := PackedByteArray()
	var bnd_start_x := PackedByteArray()
	var bnd_start_y := PackedByteArray()
	var bnd_end_x := PackedByteArray()
	var bnd_end_y := PackedByteArray()
	var saved_control_list_interface: PackedByteArray = save_control_list_interface(parsed_control_list_interface)
	
	for current_file in files:
		GlobalLogger.log_info("Saving file " + current_file + "...")
		file_index.append_array(PackedByteArray([1, 0, 0, 0]))
		
		file_name = current_file.to_utf8_buffer()
		file_name.resize(128)
		
		file_index.append_array(file_name)
		
		resized_current_offset = PackedByteArray([0, 0, 0, 0])
		resized_current_offset.encode_u32(0, current_offset)
		
		file_index.append_array(resized_current_offset)
		
		resized_file_size = PackedByteArray([0, 0, 0, 0])
		
		if current_file == "ControlList_Interface.txt":
			resized_file_size.encode_u32(0, len(saved_control_list_interface))
		else:
			resized_file_size.encode_u32(0, files[current_file]["size"])
		
		file_index.append_array(resized_file_size)
		file_index.append_array(resized_file_size)
		file_index.append_array(PackedByteArray([0, 0, 0, 0, 0, 0, 0, 0]))
		
		if current_file == "abusedata.ojs":
			if swears == []:
				parse_abusedata(files["abusedata.ojs"]["data"])
			for swear in swears:
				swear = to_iso88591(swear)
				file_to_save.append_array(swear)
				file_to_save.append_array(PackedByteArray([13, 10]))
				
				current_offset += len(swear) + 2
			
			current_offset -= 2
			file_to_save.resize(len(file_to_save) - 2)
		elif current_file.ends_with(".bnd"):
			bnd_file = PackedByteArray([255, 255, 255, 255])
			
			bnd_obj_count = PackedByteArray([0, 0])
			bnd_obj_count.encode_u16(0, files[current_file]["data"]["object_count"])
			
			bnd_file.append_array(bnd_obj_count)
			
			for bnd_object in files[current_file]["data"]["objects"]:
				if bnd_object.has("extra_data"):
					bnd_file.append_array(bnd_object["extra_data"])
				else:
					bnd_start_x = PackedByteArray([0, 0, 0, 0])
					bnd_start_x.encode_u32(0, bnd_object["start_x"])
					
					bnd_file.append_array(bnd_start_x)
					
					bnd_start_y = PackedByteArray([0, 0, 0, 0])
					bnd_start_y.encode_u32(0, bnd_object["start_y"])
					
					bnd_file.append_array(bnd_start_y)
					
					bnd_end_x = PackedByteArray([0, 0, 0, 0])
					bnd_end_x.encode_u32(0, bnd_object["end_x"])
					
					bnd_file.append_array(bnd_end_x)
					
					bnd_end_y = PackedByteArray([0, 0, 0, 0])
					bnd_end_y.encode_u32(0, bnd_object["end_y"])
					
					bnd_file.append_array(bnd_end_y)
			
			file_to_save.append_array(bnd_file)
			current_offset += len(bnd_file)
		elif current_file == "ControlList_Interface.txt":
			file_to_save.append_array(saved_control_list_interface)
			
			current_offset += len(saved_control_list_interface)
		else:
			file_to_save.append_array(files[current_file]["data"])
			
			current_offset += len(files[current_file]["data"])
	
	file_to_save.append_array(file_index)
	
	var filea = FileAccess.open(file_path, FileAccess.WRITE)
	filea.store_buffer(file_to_save)
	filea.close()
	
	GlobalLogger.log_info("Successfully saved!")

func save_control_list_interface(control_list_interface: Dictionary):
	var return_control_list_interface := PackedByteArray()
	
	for object in control_list_interface:
		return_control_list_interface.append_array(object.to_utf8_buffer())
		
		for value in control_list_interface[object]["values"]:
			return_control_list_interface.append(9)
			return_control_list_interface.append_array(value.to_utf8_buffer())
		
		return_control_list_interface.append_array(PackedByteArray([13, 10]))
		
		if len(control_list_interface[object]) > 1:
			return_control_list_interface.append_array([123, 13, 10])
			
			for deep_object in control_list_interface[object]:
				if deep_object.begins_with("set_"):
					return_control_list_interface.append_array(PackedByteArray([9]) + "SET".to_utf8_buffer())
					
					return_control_list_interface.append(9)
					return_control_list_interface.append_array(control_list_interface[object][deep_object]["values"][0].to_utf8_buffer())
					
					return_control_list_interface.append(9)
					return_control_list_interface.append_array(control_list_interface[object][deep_object]["values"][1].to_utf8_buffer())
					
					return_control_list_interface.append_array([13, 10, 9, 123, 13, 10])
					
					for set_object in control_list_interface[object][deep_object]:
						if set_object != "values":
							return_control_list_interface.append_array([9, 9])
							return_control_list_interface.append_array(set_object.to_utf8_buffer())
							
							for value in control_list_interface[object][deep_object][set_object]["values"]:
								return_control_list_interface.append(9)
								return_control_list_interface.append_array(value.to_utf8_buffer())
							
							return_control_list_interface.append_array(PackedByteArray([13, 10]))
					
					return_control_list_interface.append_array(PackedByteArray([9, 125, 13, 10]))
				if deep_object != "values" and not deep_object.begins_with("set_"):
					return_control_list_interface.append_array(PackedByteArray([9]) + deep_object.to_utf8_buffer())
					
					for value in control_list_interface[object][deep_object]["values"]:
						return_control_list_interface.append(9)
						
						if value.begins_with("\"") and not value.ends_with("\""):
							return_control_list_interface.append_array(value.to_utf8_buffer() + "\"".to_utf8_buffer())
						else:
							return_control_list_interface.append_array(value.to_utf8_buffer())
					
					return_control_list_interface.append_array(PackedByteArray([13, 10]))
			
			return_control_list_interface.append_array(PackedByteArray([125, 13, 10]))
	
	return return_control_list_interface

func parse_control_list_interface(control_list_interface: PackedByteArray):
	var lines := [PackedByteArray()]
	var x := 0
	var y := 0
	
	while x != len(control_list_interface):
		if control_list_interface[x] == 13:
			x += 1
			
			if control_list_interface[x] == 10:
				x += 1
				y += 1
				lines.append(PackedByteArray())
			
			continue
		
		lines[y].append_array(PackedByteArray([control_list_interface[x]]))
		x += 1
	
	var key := ""
	var indents := 0
	
	var temp_value := ""
	var values := []
	var i := 0
	var encountered_set := false
	
	var stored_key := ""
	var set_key := ""
	
	var encountered_comment_at_end := false
	
	var temp_i := 0
	
	for line in lines:
		if line == PackedByteArray(): # get rid of empty lines
			continue
		
		if len(line) > 1:
			if line[0] == 47 and line[1] == 47: # get rid of commented lines
				continue
			
			if line[0] == 9 and line[1] == 47 and line[2] == 47: # get rid of commented lines with a tab
				continue
		
		if line == PackedByteArray([9]): # get rid of lines with only a tab
			continue
		
		# remove the tabs at the end of lines (they break the parser really bad for some reason)
		if line[len(line) - 1] == 9:
			line.resize(len(line) - 1)
			
			temp_i = len(line) - 1
			
			while i < len(line) and line[temp_i] == 9:
				line.resize(len(line) - 1)
				temp_i -= 1
		
		# remove the spaces at the end of lines (yes they break the parser too)
		if line[len(line) - 1] == 32:
			line.resize(len(line) - 1)
			
			temp_i = len(line) - 1
			
			while i < len(line) and line[temp_i] == 32:
				line.resize(len(line) - 1)
				temp_i -= 1
		
		if line == PackedByteArray(): # get rid of empty lines (again)
			continue
		
		if line == PackedByteArray([9]): # get rid of lines with only a tab (again)
			continue
		
		if len(line) > 1:
			if line[0] == 123 or line[1] == 123:
				if !encountered_set:
					stored_key = key
				else:
					encountered_set = false
				
				indents += 1
				continue
		else:
			if line[0] == 123:
				stored_key = key
				indents += 1
				continue
		
		key = ""
		values = []
		temp_value = ""
		
		if len(line) > 1:
			if line[0] == 125 or line[1] == 125:
				indents -= 1
				encountered_set = false
				continue
		else:
			if line[0] == 125:
				indents -= 1
				continue
			elif line[0] == 123:
				indents += 1
				continue
		
		if indents == 0:
			i = 0
		elif indents == 1:
			i = 1
			
			if line[i] == 32:
				i += 3
			
			if line[i - 1] == 32 and line[i] == 9:
				i += 1
		elif indents == 2:
			i = 2
			
			if line[i] == 32:
				i += 6
		
		while i < len(line) and line[i] != 9 and line[i] != 32: # get the key
			key += char(line[i])
			i += 1
			
			if key == "SET":
				encountered_set = true
		
		while i < len(line) and line[i] == 9: # skip to the values
			i += 1
		
		if i >= len(line): # if there are no values
			if indents == 0:
				parsed_control_list_interface[key] = {"values": []}
			elif indents == 1:
				parsed_control_list_interface[stored_key][key] = {"values": []}
			continue
		
		if indents == 0:
			while i < len(line) - 1: #get the values
				if line[i] == 9: # skip to the next value once we reach a tab
					while line[i] == 9 and i < len(line) - 1:
						i += 1
					
					values.append(temp_value)
					temp_value = ""
					continue
				
				temp_value += char(line[i])
				
				i += 1
			
			temp_value += char(line[i])
			
			values.append(temp_value)
			
			parsed_control_list_interface[key] = {"values": values}
		elif encountered_set:
			while i < len(line) - 1: #get the values
				if line[i] == 9: # skip to the next value once we reach a tab
					while line[i] == 9 and i < len(line) - 1:
						i += 1
					
					values.append(temp_value)
					temp_value = ""
					continue
				
				temp_value += char(line[i])
				
				i += 1
			
			temp_value += char(line[i])
			
			values.append(temp_value)
			
			key = "set_" + values[1]
			set_key = key
			
			parsed_control_list_interface[stored_key][key] = {"values": values}
		elif indents == 1:
			while i < len(line) - 1: #get the values
				if line[i] == 9: # skip to the next value once we reach a tab
					while i < len(line) - 1 and line[i] == 9:
						i += 1
					
					values.append(temp_value)
					temp_value = ""
					continue
				
				if line[i] == 47:
					if line[i + 1] == 47:
						encountered_comment_at_end = true
						
						while line[i] == 47 or line[i] == 32 or line[i] == 9:
							i -= 1
							temp_value = temp_value.substr(0, len(temp_value) - 1)
						
						break
				
				temp_value += char(line[i])
				
				i += 1
			
			if not encountered_comment_at_end:
				temp_value += char(line[i])
			
			encountered_comment_at_end = false
			
			values.append(temp_value)
			
			parsed_control_list_interface[stored_key][key] = {"values": values}
		elif indents == 2:
			while i < len(line) - 1: #get the values
				if line[i] == 9: # skip to the next value once we reach a tab
					while line[i] == 9 and i < len(line) - 1:
						i += 1
					
					if i >= len(line):
						continue
					
					values.append(temp_value)
					temp_value = ""
					continue
				
				temp_value += char(line[i])
				
				i += 1
			
			temp_value += char(line[i])
			
			values.append(temp_value)
			
			parsed_control_list_interface[stored_key][set_key][key] = {"values": values}

func parse(p_file_path: String):
	GlobalLogger.log_info("Parsing file " + p_file_path + "...")
	file_path = p_file_path
	
	var loading_window := load("res://Objects/LoadingWindow.tscn")
	var loading_window_instantiated: Window = loading_window.instantiate()
	get_tree().current_scene.add_child(loading_window_instantiated)
	
	await get_tree().create_timer(0.1).timeout
	
	files = {}
	ojs_files = {}
	parsed_control_list_interface = {}
	lowercase_files = {}
	ojs_keys_lower = {}
	swears = []
	
	for child in get_tree().current_scene.get_node("DataExplorer").get_node("ScrollContainer").get_node("VBoxContainer").get_children():
		child.queue_free()
	
	for child in get_tree().current_scene.get_node("DataExplorer").get_node("StateViewer").get_node("VBoxContainer").get_children():
		child.queue_free()
	
	for child in get_tree().current_scene.get_node("StatePreview").get_children():
		child.queue_free()
	
	file = FileAccess.open(file_path, FileAccess.READ_WRITE)
	
	file.seek(0)
	
	file_type = file.get_32()
	file_count = file.get_32()
	
	file.seek(file.get_length() - (file_count * 152))
	
	var unk_int := 0
	var file_name := ""
	var offset := 0
	var size := 0
	var unk_bytes := PackedByteArray()
	var unnamed_counter := 1
	
	for i in range(file_count + 1):
		unk_int = file.get_32()
		file_name = file.get_buffer(128).get_string_from_ascii()
		GlobalLogger.log_info("Parsing file " + file_name + "...")
		offset = file.get_32()
		size = max(file.get_32(), file.get_32())
		unk_bytes = file.get_buffer(8)
		
		var data = PackedByteArray()
		
		file.seek(offset)
		
		if file_name == "abusedata.ojs":
			data = file.get_buffer(size)
		elif file_name == "ControlList_Interface.txt" or file_name == "ControlList_Playing.txt":
			data = file.get_buffer(size)
			parse_control_list_interface(data)
		elif file_name.substr(len(file_name) - 4, 4) == ".bnd":
			data = parse_bnd(file.get_buffer(size))
		else:
			data = file.get_buffer(size)
		
		file.seek(file.get_length() - ((file_count - i) * 152))
		
		if file_name == "":
			file_name = "Unnamed_" + str(unnamed_counter)
			unnamed_counter += 1
		
		files[file_name] = {
			"unk_int": unk_int,
			"offset": offset,
			"size": size,
			"unk_bytes": unk_bytes,
			"data": data,
		}
		
		lowercase_files[file_name.to_lower()] = file_name
		
		ojs_files[file_name] = {
			"file_format": 0,
			"color_format": 0,
			"frame_count": 0,
			"frames": [],
			"is_bmp16": true
		}
		
		ojs_keys_lower[file_name.to_lower()] = file_name
		
		if file_name.ends_with(".ojs") and file_name != "abusedata.ojs" or file_name.ends_with(".oja") or file_name.ends_with(".ojt") or file_name.ends_with("oji"):
			if data[3] == 5:
				parse_ojs(data, file_name)
		
		if file_name != "" and i != 0:
			var deb_instantiated: Button = data_explorer_button.instantiate()
			
			deb_instantiated.text = file_name
			deb_instantiated.name = file_name
			
			deb_instantiated.custom_minimum_size.x = 327.0
			
			get_tree().current_scene.get_node("DataExplorer").get_node("ScrollContainer").get_node("VBoxContainer").add_child(deb_instantiated)
	
	for key in parsed_control_list_interface:
		if key != "NUMBER_OF_STATE" and key != "NUMBER_OF_DIALOG":
			var svb_instantiated: Button = state_viewer_button.instantiate()
			
			svb_instantiated.text = key
			svb_instantiated.name = key
			
			get_tree().current_scene.get_node("DataExplorer").get_node("StateViewer").get_node("VBoxContainer").add_child(svb_instantiated)
	
	if not already_loaded:
		get_tree().current_scene.get_node("ToBegin").queue_free()
		get_tree().current_scene.get_node("LoadingWindow").queue_free()
	
	#DiscordRPC.state = "Editing " + file_path.get_file()
	#DiscordRPC.large_image = "file_" + file_path.get_file().substr(len(file_path.get_file()) - 3, 3)
	#DiscordRPC.refresh()
	
	GlobalLogger.log_info("Parsed file " + p_file_path + "!")
	
	if parsed_control_list_interface.has("STATE_LOGIN"):
		show_state("STATE_LOGIN")
	elif parsed_control_list_interface.has("STATE_PLAYING"):
		show_state("STATE_PLAYING")
	
	already_loaded = true

# Credits: Ivan Skodje
# https://ivanskodje.com/conversion-between-binary-decimal/
func binary_to_decimal(binary_string: String):
	var decimal_value := 0
	var count := 0
	var temp: int
	var new_binary_string := int(binary_string)
	
	while(new_binary_string != 0):
		temp = new_binary_string % 10
		new_binary_string /= 10
		@warning_ignore("narrowing_conversion")
		decimal_value += temp * pow(2, count)
		count += 1
	
	return decimal_value

func bmp24_to_bmp16(bmp_file: PackedByteArray, width: int, height: int) -> PackedByteArray:
	var input_padding_per_row := (4 - (width * 3) % 4) % 4
	
	var rows: Array[PackedByteArray] = []
	var index := 0
	for y in range(height):
		var row := PackedByteArray()
		for x in range(width):
			var b := bmp_file[index]
			index += 1
			
			var g := bmp_file[index]
			index += 1
			
			var r := bmp_file[index]
			index += 1
			
			var r5 := (r >> 3)
			var g5 := (g >> 3)
			var b5 := (b >> 3)
			
			var pixel16 := (r5 << 10) | (g5 << 5) | b5
			row.append(pixel16 & 0xFF)
			row.append((pixel16 >> 8) & 0xFF)
		
		index += input_padding_per_row
		rows.append(row)
	
	rows.reverse()
	
	var new_bmp := PackedByteArray()
	
	for row in rows:
		new_bmp.append_array(row) # row must be raw pixels only
	
	return new_bmp

func bmp16_to_bmp24(bmp_file: PackedByteArray, width: int, height: int, padding: bool = false) -> PackedByteArray:
	var new_bmp := PackedByteArray()
	var padding_per_row := (4 - (width * 3) % 4) % 4
	
	
	var padding_per_row_16 := 0
	if padding:
		padding_per_row_16 = (width * 2) % 4
	
	var index := 0
	for y in range(height):
		for x in range(width):
			var pixel := bmp_file.decode_u16(index)
			index += 2
			
			var b5 := pixel & 0b11111
			var g5 := (pixel >> 5) & 0b11111
			var r5 := (pixel >> 10) & 0b11111
			
			var b8 := (b5 << 3) | (b5 >> 2)
			var g8 := (g5 << 3) | (g5 >> 2)
			var r8 := (r5 << 3) | (r5 >> 2)
			
			new_bmp.append(b8)
			new_bmp.append(g8)
			new_bmp.append(r8)
		
		index += padding_per_row_16
		
		for i in range(padding_per_row):
			new_bmp.append(0)
	
	return new_bmp

func parse_ojs(ojs_file: PackedByteArray, file_name: String):
	if ojs_files.has(file_name):
		pass
	
	var file_format := ojs_file.decode_u16(0)
	var color_format := ojs_file.slice(2, 4)
	var frame_count := ojs_file.decode_u16(4)
	
	ojs_files[file_name] = {
		"file_format": file_format,
		"color_format": color_format,
		"frame_count": frame_count,
		"frames": []
	}
	
	var transparent_color := PackedByteArray()
	var x := 0
	var y := 0
	var width := 0
	var height := 0
	var offset := 0
	var size := 0
	var unk := 0
	
	var seek_pos := 6
	var offset_minus_by := 0
	var first_frame := true
	
	for i in range(frame_count):
		transparent_color = ojs_file.slice(seek_pos, seek_pos + 2)
		x = ojs_file.decode_u16(seek_pos + 2)
		y = ojs_file.decode_u16(seek_pos + 4)
		width = ojs_file.decode_u16(seek_pos + 6)
		height = ojs_file.decode_u16(seek_pos + 8)
		offset = ojs_file.decode_u32(seek_pos + 10) - offset_minus_by
		
		if first_frame:
			offset_minus_by = offset
			offset = 0
		
		size = ojs_file.decode_u32(seek_pos + 14)
		unk = ojs_file.decode_u16(seek_pos + 18)
		
		seek_pos += 20
		
		ojs_files[file_name]["frames"].append({
			"transparent_color": transparent_color,
			"x": x,
			"y": y,
			"width": width,
			"height": height,
			"offset": offset,
			"size": size,
			"unk": unk,
			"data": PackedByteArray(),
			"16-bit-data": PackedByteArray()
		})
		
		if i == 0:
			first_frame = false
	
	var ojs_bmp_data := PackedByteArray()
	var bmp_data := PackedByteArray()
	var bmp_data_second := PackedByteArray()
	
	var row_size := 0
	var image_data_split := []
	var data_to_append := PackedByteArray()
	var reconstructed_image_data := PackedByteArray()
	var padding_bytes := 0
	var avar := PackedByteArray()
	
	for i in range(frame_count):
		# reusing variable names lmao
		size = ojs_files[file_name]["frames"][i]["size"]
		width = ojs_files[file_name]["frames"][i]["width"]
		height = ojs_files[file_name]["frames"][i]["height"]
		
		if i != 0: # for some reason the offset is sometimes something higher which shifts the data and generates errors, this fixes that
			offset = ojs_files[file_name]["frames"][i]["offset"]
		else:
			offset = 0
		
		seek_pos = 8 + (frame_count * 20) + offset
		ojs_bmp_data = ojs_file.slice(seek_pos, seek_pos + size)
		
		ojs_files[file_name]["frames"][i]["16-bit-data"] = ojs_bmp_data
		
		# First half
		bmp_data = PackedByteArray()
		bmp_data.append_array("BM".to_utf8_buffer())
		
		# Second half
		bmp_data_second = PackedByteArray([0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0])
		bmp_data_second.append_array(var_to_bytes(width).slice(4))
		bmp_data_second.append_array(var_to_bytes(height).slice(4))
		bmp_data_second.append_array(PackedByteArray([1, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 14, 0, 0, 196, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
		
		# O2Jam devs reverse their image files and remove the header most likely for these reasons:
		# > The game had to store many BMPs, so they removed the header and padding to compact them.
		# > Having to reorder the BMPs to be top to down must have taken some processing power, so they just reversed them in the files.
		#   > However, you would expect for DirectX or DirectDraw to render BMPs from bottom to top, but I guess the devs never saw that one through. (or maybe i am stupid)
		
		row_size = width * 2
		image_data_split = []
		
		padding_bytes = 0
		
		# sailing the seas to learn my abcs (or xyzs in this case)
		for z in range(height):
			seek_pos = z * row_size
			
			data_to_append = ojs_bmp_data.slice(seek_pos, seek_pos + row_size)
			
			image_data_split.append(data_to_append)
		
		image_data_split.reverse()
		reconstructed_image_data = PackedByteArray()
		
		for row in image_data_split:
			reconstructed_image_data.append_array(row)
		
		avar = bmp16_to_bmp24(reconstructed_image_data, width, height)
		
		if reconstructed_image_data == avar:
			ojs_files[file_name]["is_bmp16"] = true
		else:
			reconstructed_image_data = avar
			ojs_files[file_name]["is_bmp16"] = false
		
		bmp_data.append_array(var_to_bytes(len(reconstructed_image_data) + 54 + padding_bytes).slice(4))
		bmp_data.append_array(bmp_data_second)
		bmp_data.append_array(reconstructed_image_data)
		
		ojs_files[file_name]["frames"][i]["data"] = bmp_data
