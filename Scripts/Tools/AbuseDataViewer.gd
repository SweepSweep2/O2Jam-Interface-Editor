extends Window

func _on_close_requested() -> void:
	#DiscordRPC.details = "Home"
	#DiscordRPC.refresh()
	
	queue_free()

func _on_proceed_pressed() -> void:
	$Warning.visible = false
	
	File.parse_abusedata(File.files["abusedata.ojs"]["data"])
	
	for a in range(len(File.swears)):
		var line_edit := LineEdit.new()
		line_edit.text = File.swears[a]
		line_edit.custom_minimum_size.x = 520
		line_edit.text_changed.connect(_line_edit_text_changed)
		
		var remove_button := Button.new()
		remove_button.text = "Remove"
		remove_button.custom_minimum_size.x = 116
		remove_button.pressed.connect(_remove_button_pressed)
		remove_button.toggle_mode = true
		
		var hbox_container := HBoxContainer.new()
		hbox_container.add_child(line_edit)
		hbox_container.add_child(remove_button)
		
		$ScrollContainer/VBoxContainer.add_child(hbox_container)
	
	var add_new_button := Button.new()
	add_new_button.text = "Add"
	add_new_button.pressed.connect(_add_new_button_pressed)
	
	$ScrollContainer/VBoxContainer.add_child(add_new_button)
	$ScrollContainer.visible = true

func _remove_button_pressed():
	for i in range(len($ScrollContainer/VBoxContainer.get_children())):
		if $ScrollContainer/VBoxContainer.get_children()[i].get_child(1).button_pressed:
			$ScrollContainer/VBoxContainer.get_children()[i].queue_free()
			File.swears.remove_at(i)
			
			break

func _add_new_button_pressed():
	File.swears.append("")
	
	var line_edit := LineEdit.new()
	line_edit.text = ""
	line_edit.custom_minimum_size.x = 520
	line_edit.text_changed.connect(_line_edit_text_changed)
	
	var remove_button := Button.new()
	remove_button.text = "Remove"
	remove_button.custom_minimum_size.x = 116
	remove_button.pressed.connect(_remove_button_pressed)
	remove_button.toggle_mode = true
	
	var hbox_container := HBoxContainer.new()
	hbox_container.add_child(line_edit)
	hbox_container.add_child(remove_button)
	
	$ScrollContainer/VBoxContainer.add_child(hbox_container)

func _line_edit_text_changed(new_text: String):
	for i in range(len($ScrollContainer/VBoxContainer.get_children())):
		if $ScrollContainer/VBoxContainer.get_children()[i].get_child(0).has_focus():
			File.swears[i] = new_text
			break
