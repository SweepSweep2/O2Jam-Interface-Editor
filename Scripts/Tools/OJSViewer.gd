extends Window

@onready var file_name: String
var current_frame := 1

var regex := RegEx.new()
var old_text := "0"
var old_text_y := "0"

var open_file := load("res://Objects/AddFrameFilePicker.tscn")

func _ready() -> void:
	title = file_name + " - OJS Viewer"
	
	#DiscordRPC.details = "Viewing " + file_name
	#DiscordRPC.refresh()
	
	regex.compile("^[0-9]*$")
	
	var x := 0
	
	if !$Main.sprite_frames.has_animation(file_name):
		$Main.sprite_frames.add_animation(file_name)
		$Main.sprite_frames.set_animation_speed(file_name, 10)
		$Main.sprite_frames.set_animation_loop(file_name, true)
	
	File.parse_ojs(File.files[file_name]["data"], file_name)
	
	for image in File.ojs_files[file_name]["frames"]:
		var img := Image.new()
		img.load_bmp_from_buffer(image["data"])
		
		var tex := ImageTexture.create_from_image(img)
		
		$Main.sprite_frames.add_frame(file_name, tex)
	
	var root_item: TreeItem = $FrameViewer.create_item()
	root_item.set_text(0, "Frames")
	
	var frames := []
	
	for i in range(len(File.ojs_files[file_name]["frames"])):
		frames.append($FrameViewer.create_item(root_item))
		frames[i].set_text(0, "| Frame " + str(i + 1))
		frames[i].set_metadata(0, {"frame": str(i)})
		
		var img := Image.new()
		img.load_bmp_from_buffer(File.ojs_files[file_name]["frames"][i]["data"])
		
		var tex := ImageTexture.create_from_image(img)
		
		if tex:
			var _max_size := Vector2(24, 24)
			var tex_size := tex.get_size()
			
			var scale_factor: float = min(
				_max_size.x / tex_size.x,
				_max_size.y / tex_size.y
			)
			
			img.resize(
				int(tex_size.x * scale_factor),
				int(tex_size.y * scale_factor),
				Image.INTERPOLATE_NEAREST
			)
			
			tex = ImageTexture.create_from_image(img)
			
			frames[i].set_icon(0, tex)
	
	$TopBar/FrameCount.text = "Frames: " + str(len(File.ojs_files[file_name]["frames"]))
	$TopBar/Encoder.text = "Encoder: " + ("%02X" % File.ojs_files[file_name]["color_format"][0]) + ("%02X" % File.ojs_files[file_name]["color_format"][1])
	$TopBar/TransparentColor.text = "Transparent Color: " + ("%02X" % File.ojs_files[file_name]["frames"][0]["transparent_color"][0]) + ("%02X" % File.ojs_files[file_name]["frames"][0]["transparent_color"][1])
	
	$Main.play(file_name)

func _on_close_requested() -> void:
	#DiscordRPC.details = "Home"
	#DiscordRPC.refresh()
	
	#convert_to_ojs()
	
	queue_free()

func _on_frame_viewer_item_mouse_selected(_mouse_position: Vector2, _mouse_button_index: int) -> void:
	if $FrameViewer.get_selected().get_metadata(0) != null:
		$FrameMetadataPanel/SelectAFrame.visible = false
		
		$FrameMetadataPanel/WidthLabel.visible = true
		$FrameMetadataPanel/SizeLabel.visible = true
		$FrameMetadataPanel/OffsetLabel.visible = true
		$FrameMetadataPanel/HeightLabel.visible = true
		$FrameMetadataPanel/XLabel.visible = true
		$FrameMetadataPanel/YLabel.visible = true
		
		$FrameMetadataPanel/X.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["x"])
		$FrameMetadataPanel/X.visible = true
		
		$FrameMetadataPanel/Y.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["y"])
		$FrameMetadataPanel/Y.visible = true
		
		$FrameMetadataPanel/Width.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["width"])
		$FrameMetadataPanel/Width.visible = true
		
		$FrameMetadataPanel/Height.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["height"])
		$FrameMetadataPanel/Height.visible = true
		
		$FrameMetadataPanel/Size.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["size"])
		$FrameMetadataPanel/Size.visible = true
		
		$FrameMetadataPanel/Offset.text = str(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["offset"])
		$FrameMetadataPanel/Offset.visible = true
		
		$TopBar/DeselectFrame.visible = true
		$TopBar/ReplaceFrame.visible = true
		$TopBar/ExportFrame.visible = true
		
		$Main.stop()
		$Main.frame = int($FrameViewer.get_selected().get_metadata(0)["frame"])
	else:
		$FrameMetadataPanel/SelectAFrame.visible = true
		$FrameMetadataPanel/Offset.visible = false
		$FrameMetadataPanel/Size.visible = false
		$FrameMetadataPanel/Height.visible = false
		$FrameMetadataPanel/Width.visible = false
		$FrameMetadataPanel/Y.visible = false
		$FrameMetadataPanel/X.visible = false
		$TopBar/DeselectFrame.visible = false
		$TopBar/ReplaceFrame.visible = false
		$TopBar/ExportFrame.visible = false
		$FrameMetadataPanel/WidthLabel.visible = true
		$FrameMetadataPanel/SizeLabel.visible = true
		$FrameMetadataPanel/OffsetLabel.visible = true
		$FrameMetadataPanel/HeightLabel.visible = true
		$FrameMetadataPanel/XLabel.visible = true
		$FrameMetadataPanel/YLabel.visible = true
		
		$Main.play(file_name)

func _on_delete_frame_pressed() -> void:
	if $FrameViewer.get_selected() != null:
		File.ojs_files[file_name]["frames"].remove_at(int($FrameViewer.get_selected().get_metadata(0)["frame"]))
		$Main.sprite_frames.remove_frame(file_name, int($FrameViewer.get_selected().get_metadata(0)["frame"]))
		
		refresh_viewer()

func _on_deselect_frame_pressed() -> void:
	$FrameMetadataPanel/SelectAFrame.visible = true
	$FrameMetadataPanel/Offset.visible = false
	$FrameMetadataPanel/Size.visible = false
	$FrameMetadataPanel/Height.visible = false
	$FrameMetadataPanel/Width.visible = false
	$FrameMetadataPanel/Y.visible = false
	$FrameMetadataPanel/X.visible = false
	$TopBar/DeselectFrame.visible = false
	$TopBar/ReplaceFrame.visible = false
	$TopBar/ExportFrame.visible = false
	$FrameMetadataPanel/WidthLabel.visible = false
	$FrameMetadataPanel/SizeLabel.visible = false
	$FrameMetadataPanel/OffsetLabel.visible = false
	$FrameMetadataPanel/HeightLabel.visible = false
	$FrameMetadataPanel/XLabel.visible = false
	$FrameMetadataPanel/YLabel.visible = false
	
	$Main.play(file_name)

func recalculate_offsets():
	for i in range(len(File.ojs_files[file_name]["frames"])):
		if i == 0:
			File.ojs_files[file_name]["frames"][i]["offset"] = 0
		else:
			File.ojs_files[file_name]["frames"][i]["offset"] = File.ojs_files[file_name]["frames"][i - 1]["offset"] + File.ojs_files[file_name]["frames"][i - 1]["size"]

func convert_to_ojs():
	var ojs_file := PackedByteArray()
	
	var resized_ojs_format := PackedByteArray([0, 0])
	resized_ojs_format.encode_u16(0, File.ojs_files[file_name]["file_format"])
	
	ojs_file.append_array(resized_ojs_format)
	ojs_file.append_array(File.ojs_files[file_name]["color_format"])
	
	var resized_ojs_frame_count := PackedByteArray([0, 0])
	resized_ojs_frame_count.encode_u16(0, File.ojs_files[file_name]["frame_count"])
	
	var frame_data := []
	
	ojs_file.append_array(resized_ojs_frame_count)
	
	var i := 0
	
	for frame in File.ojs_files[file_name]["frames"]:
		if i == 0:
			ojs_file.append_array(frame["transparent_color"])
		else:
			ojs_file.append_array(PackedByteArray([0, 0]))
		
		var frame_x := PackedByteArray([0, 0])
		frame_x.encode_u16(0, frame["x"])
		
		ojs_file.append_array(frame_x)
		
		var frame_y := PackedByteArray([0, 0])
		frame_y.encode_u16(0, frame["y"])
		
		ojs_file.append_array(frame_y)
		
		var frame_width := PackedByteArray([0, 0])
		frame_width.encode_u16(0, frame["width"])
		
		ojs_file.append_array(frame_width)
		
		var frame_height := PackedByteArray([0, 0])
		frame_height.encode_u16(0, frame["height"])
		
		ojs_file.append_array(frame_height)
		
		var frame_offset := PackedByteArray([0, 0, 0, 0])
		frame_offset.encode_u32(0, frame["offset"])
		
		ojs_file.append_array(frame_offset)
		
		var frame_size := PackedByteArray([0, 0, 0, 0])
		frame_size.encode_u32(0, frame["size"])
		
		ojs_file.append_array(frame_size)
		
		var frame_unk := PackedByteArray([0, 0])
		frame_unk.encode_u16(0, frame["unk"])
		
		ojs_file.append_array(frame_unk)
		frame_data.append(frame["16-bit-data"])
		
		i += 1
	
	ojs_file.append_array(PackedByteArray([0, 0]))
	
	for data in frame_data:
		ojs_file.append_array(data)
	
	File.files[file_name]["data"] = ojs_file
	File.files[file_name]["size"] = len(ojs_file)

func refresh_viewer():
	$FrameViewer.get_root().free()
		
	var root_item: TreeItem = $FrameViewer.create_item()
	root_item.set_text(0, "Frames")
	
	var frames := []
	
	for i in range(len(File.ojs_files[file_name]["frames"])):
		frames.append($FrameViewer.create_item(root_item))
		frames[i].set_text(0, "| Frame " + str(i + 1))
		frames[i].set_metadata(0, {"frame": str(i)})
		
		var img := Image.new()
		img.load_bmp_from_buffer(File.ojs_files[file_name]["frames"][i]["data"])
		
		var tex := ImageTexture.create_from_image(img)
		
		if tex:
			var _max_size := Vector2(24, 24)
			var tex_size := tex.get_size()

			var scale_factor: float = min(
				_max_size.x / tex_size.x,
				_max_size.y / tex_size.y
			)

			img.resize(
				int(tex_size.x * scale_factor),
				int(tex_size.y * scale_factor),
				Image.INTERPOLATE_NEAREST
			)
			
			tex = ImageTexture.create_from_image(img)
			
			frames[i].set_icon(0, tex)
	
	$FrameMetadataPanel/SelectAFrame.visible = true
	$FrameMetadataPanel/Offset.visible = false
	$FrameMetadataPanel/Size.visible = false
	$FrameMetadataPanel/Height.visible = false
	$FrameMetadataPanel/Width.visible = false
	$FrameMetadataPanel/Y.visible = false
	$FrameMetadataPanel/X.visible = false
	$TopBar/DeselectFrame.visible = false
	$TopBar/ReplaceFrame.visible = false
	$TopBar/ExportFrame.visible = false
	$FrameMetadataPanel/WidthLabel.visible = false
	$FrameMetadataPanel/SizeLabel.visible = false
	$FrameMetadataPanel/OffsetLabel.visible = false
	$FrameMetadataPanel/HeightLabel.visible = false
	$FrameMetadataPanel/XLabel.visible = false
	$FrameMetadataPanel/YLabel.visible = false
	
	$Main.stop()
	$Main.sprite_frames.clear(file_name)
	
	for i in range(len(File.ojs_files[file_name]["frames"])):
		var imga := Image.new()
		imga.load_bmp_from_buffer(File.ojs_files[file_name]["frames"][i]["data"])
		
		var tex := ImageTexture.create_from_image(imga)
		
		$Main.sprite_frames.add_frame(file_name, tex)
	
	$Main.play(file_name)
	
	recalculate_offsets()
	convert_to_ojs()

func _on_add_frame_pressed() -> void:
	var open_file_instantiated: FileDialog = open_file.instantiate()
	open_file_instantiated.ojs_file = file_name
	
	open_file_instantiated.refresh_ojs_viewer.connect(refresh_viewer)
	
	get_tree().current_scene.add_child(open_file_instantiated)

func _on_replace_frame_pressed() -> void:
	var open_file_instantiated: FileDialog = open_file.instantiate()
	open_file_instantiated.ojs_file = file_name
	open_file_instantiated.replace_frame = true
	open_file_instantiated.replace_frame_index = int($FrameViewer.get_selected().get_metadata(0)["frame"])
	
	open_file_instantiated.refresh_ojs_viewer.connect(refresh_viewer)
	
	get_tree().current_scene.add_child(open_file_instantiated)

# Credits to @plambrecht on Godot Forums
# https://forum.godotengine.org/t/lineedit-numeric-only-restricted-range/11689
func _on_x_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["x"] = int(new_text)
		old_text = $FrameMetadataPanel/X.text
	elif new_text == "":
		$FrameMetadataPanel/X.text = "0"
	else:
		$FrameMetadataPanel/X.text = old_text

func _on_y_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["y"] = int(new_text)
		old_text_y = $FrameMetadataPanel/Y.text
	elif new_text == "":
		$FrameMetadataPanel/Y.text = "0"
	else:
		$FrameMetadataPanel/Y.text = old_text_y

func _on_export_frame_pressed() -> void:
	var fileDialog = FileDialog.new()
	
	fileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fileDialog.display_mode = FileDialog.DISPLAY_LIST
	fileDialog.access = FileDialog.ACCESS_FILESYSTEM
	fileDialog.filters = PackedStringArray(["*.bmp"])
	fileDialog.file_selected.connect(file_selected)
	
	get_tree().current_scene.add_child(fileDialog)
	fileDialog.popup_centered(Vector2i(800, 600))

func file_selected(path: String):
	var filea = FileAccess.open(path, FileAccess.WRITE)
	
	filea.store_buffer(File.ojs_files[file_name]["frames"][int($FrameViewer.get_selected().get_metadata(0)["frame"])]["data"])
	
	filea.close()
