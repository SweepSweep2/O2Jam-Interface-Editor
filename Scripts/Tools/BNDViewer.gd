extends Window

var file = ""
var bnd_object = load("res://Objects/BNDObject.tscn")

var current_selected = 0

var regex = RegEx.new()
var bnd_objects = []
var old_text

func on_object_selected(id: int, x: int, y: int, width: int, height: int):
	current_selected = id
	
	$Panel/SelectAnObject.visible = false
	$Panel/CurrentObject.visible = true
	$Panel/XText.visible = true
	$Panel/XInput.visible = true
	$Panel/YText.visible = true
	$Panel/YInput.visible = true
	$Panel/WidthText.visible = true
	$Panel/WidthInput.visible = true
	$Panel/HeightText.visible = true
	$Panel/HeightInput.visible = true
	
	$Panel/CurrentObject.text = "Object Selected: " + str(id)
	$Panel/XInput.text = str(x)
	$Panel/YInput.text = str(y)
	$Panel/WidthInput.text = str(width)
	$Panel/HeightInput.text = str(height)

func _ready():
	var i = 0
	
	regex.compile("^[0-9]*$")
	
	for object in File.files[file]["data"]["objects"]:
		var instantiated_bnd_object = bnd_object.instantiate()
		
		instantiated_bnd_object.object_id = i
		instantiated_bnd_object.position.x = 200 + object["start_x"]
		instantiated_bnd_object.position.y = object["start_y"]
		
		instantiated_bnd_object.x = object["start_x"]
		instantiated_bnd_object.y = object["start_y"]
		instantiated_bnd_object.end_x = object["end_x"]
		instantiated_bnd_object.end_y = object["end_y"]
		
		instantiated_bnd_object.clicked.connect(on_object_selected)
		
		add_child(instantiated_bnd_object)
		
		bnd_objects.append(instantiated_bnd_object)
		
		i += 1

func _on_close_requested() -> void:
	queue_free()

# Credits to @plambrecht on Godot Forums
# https://forum.godotengine.org/t/lineedit-numeric-only-restricted-range/11689
func _on_x_input_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		bnd_objects[current_selected].x = int(new_text)
		bnd_objects[current_selected].position.x = int(new_text) + 200
		old_text = $Panel/XInput.text
	elif new_text == "":
		$Panel/XInput.text = "0"
	else:
		$Panel/XInput.text = old_text
	
	convert_to_bnd()

func _on_y_input_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		bnd_objects[current_selected].y = int(new_text)
		bnd_objects[current_selected].position.y = int(new_text)
		old_text = $Panel/YInput.text
	elif new_text == "":
		$Panel/YInput.text = "0"
	else:
		$Panel/YInput.text = old_text
	
	convert_to_bnd()

func _on_width_input_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		bnd_objects[current_selected].end_x = int(new_text)
		old_text = $Panel/WidthInput.text
	elif new_text == "":
		$Panel/WidthInput.text = "0"
	else:
		$Panel/WidthInput.text = old_text
	
	convert_to_bnd()

func _on_height_input_text_changed(new_text: String) -> void:
	if regex.search(new_text):
		bnd_objects[current_selected].end_y = int(new_text)
		old_text = $Panel/HeightInput.text
	elif new_text == "":
		$Panel/HeightInput.text = "0"
	else:
		$Panel/HeightInput.text = old_text
	
	convert_to_bnd()

func convert_to_bnd():
	var bnd_file = PackedByteArray([255, 255, 255, 255])
	
	var resized_object_count := PackedByteArray([0, 0])
	resized_object_count.encode_u16(0, len(bnd_objects))
	
	bnd_file.append_array(resized_object_count)
	
	var resized_x = PackedByteArray([0, 0, 0, 0])
	var resized_y = PackedByteArray([0, 0, 0, 0])
	var resized_end_x = PackedByteArray([0, 0, 0, 0])
	var resized_end_y = PackedByteArray([0, 0, 0, 0])
	
	for object in bnd_objects:
		resized_x.encode_u32(0, object.x)
		bnd_file.append_array(resized_x)
		
		resized_y.encode_u32(0, object.y)
		bnd_file.append_array(resized_y)
		
		resized_end_x.encode_u32(0, object.end_x)
		bnd_file.append_array(resized_end_x)
		
		resized_end_y.encode_u32(0, object.end_y)
		bnd_file.append_array(resized_end_y)
	
	if File.files[file]["data"]["objects"].has("extra_data"):
		bnd_file.append_array(File.files[file]["data"]["objects"]["extra_data"])
	
	File.files[file]["data"] = File.parse_bnd(bnd_file)
