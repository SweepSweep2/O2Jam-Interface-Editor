extends FileDialog

signal refresh_ojs_viewer

var ojs_file
var open_file := load("res://Tools/AddFrameSelector.tscn")

# This is so we can reuse the same node for adding new frames and replacing frames.
var replace_frame := false
var replace_frame_index := 0

func _on_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	
	file.seek(28)
	
	var bits_per_pixel := file.get_16()
	
	if bits_per_pixel == 24:
		file.seek(18)
		
		var width := file.get_32()
		var height := file.get_32()
		
		file.seek(54)
		var new_data := File.bmp24_to_bmp16(file.get_buffer(file.get_length() - 54), width, height)
		
		if !replace_frame:
			File.ojs_files[ojs_file]["frames"].append({
				"transparent_color": File.ojs_files[ojs_file]["frames"][0]["transparent_color"],
				"x": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["x"],
				"y": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["y"],
				"width": width,
				"height": height,
				"offset": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["offset"] + File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["size"],
				"size": width * height * 2,
				"unk": 0,
				"data": FileAccess.get_file_as_bytes(path),
				"16-bit-data": new_data
			})
		else:
			File.ojs_files[ojs_file]["frames"][replace_frame_index] = ({
				"transparent_color": File.ojs_files[ojs_file]["frames"][0]["transparent_color"],
				"x": File.ojs_files[ojs_file]["frames"][replace_frame_index]["x"],
				"y": File.ojs_files[ojs_file]["frames"][replace_frame_index]["y"],
				"width": width,
				"height": height,
				"offset": 0,
				"size": width * height * 2,
				"unk": 0,
				"data": FileAccess.get_file_as_bytes(path),
				"16-bit-data": new_data
			})
		
		emit_signal("refresh_ojs_viewer")
	elif bits_per_pixel == 16:
		file.seek(18)
		
		var width := file.get_32()
		var height := file.get_32()
		
		file.seek(54)
		var sixteenbitdata := file.get_buffer(file.get_length() - 54)
		var twentyfourbitdata := File.bmp16_to_bmp24(sixteenbitdata, width, height, true)
		
		# First half
		var bmp_data := PackedByteArray()
		bmp_data.append_array("BM".to_utf8_buffer())
		
		# Second half
		var bmp_data_second := PackedByteArray([0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0])
		bmp_data_second.append_array(var_to_bytes(width).slice(4))
		bmp_data_second.append_array(var_to_bytes(height).slice(4))
		bmp_data_second.append_array(PackedByteArray([1, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 196, 14, 0, 0, 196, 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
		
		bmp_data.append_array(var_to_bytes(len(twentyfourbitdata) + 54).slice(4))
		bmp_data.append_array(bmp_data_second)
		bmp_data.append_array(twentyfourbitdata)
		
		var padding_per_row := (4 - (width * 3) % 4) % 4
		
		var rows = []
		var seek_pos = 54
		
		for i in range(height):
			file.seek(seek_pos)
			rows.append(file.get_buffer(width * 2))
			
			seek_pos += width * 2
			seek_pos += padding_per_row
		
		rows.reverse()
		
		var reversed_data = PackedByteArray()
		
		for row in rows:
			reversed_data.append_array(row)
		
		if !replace_frame:
			File.ojs_files[ojs_file]["frames"].append({
				"transparent_color": File.ojs_files[ojs_file]["frames"][0]["transparent_color"],
				"x": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["x"],
				"y": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["y"],
				"width": width,
				"height": height,
				"offset": File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["offset"] + File.ojs_files[ojs_file]["frames"][len(File.ojs_files[ojs_file]["frames"]) - 1]["size"],
				"size": width * height * 2,
				"unk": 0,
				"data": bmp_data,
				"16-bit-data": reversed_data
			})
		else:
			File.ojs_files[ojs_file]["frames"][replace_frame_index] = ({
				"transparent_color": File.ojs_files[ojs_file]["frames"][0]["transparent_color"],
				"x": File.ojs_files[ojs_file]["frames"][replace_frame_index]["x"],
				"y": File.ojs_files[ojs_file]["frames"][replace_frame_index]["y"],
				"width": width,
				"height": height,
				"offset": 0,
				"size": width * height * 2,
				"unk": 0,
				"data": bmp_data,
				"16-bit-data": reversed_data
			})
		
		emit_signal("refresh_ojs_viewer")
	else:
		GlobalLogger.log_info("Only 24-bit and 16-bit BMPs are allowed!")
		
		var open_file_instantiated: Window = open_file.instantiate()
		get_tree().current_scene.add_child(open_file_instantiated)
