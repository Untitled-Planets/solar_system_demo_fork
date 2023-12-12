extends Control


signal start_requested(username: String)
signal start_client(username: String, server_ip: String)
signal settings_requested
signal exit_requested

const SAVE_USERNAMES_PATH: String = "user://last_usernames.json"

@onready var _username: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/username
#@onready var multiplayer_server_ip: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer3/LineEdit
@onready var server_option: OptionButton = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer3/ServerIp as OptionButton

@onready var last_options: OptionButton = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/CenterContainer/LastUsernames as OptionButton

var last_usernames: PackedStringArray = []


func _ready() -> void:
	_username.text = "character_" + str(randi() % 10)
	
	load_options()
	
	var temp: PackedStringArray = last_usernames
	temp.reverse()
	last_options.clear()
	last_options.add_item("", 0)
	for i in range(temp.size()):
		last_options.add_item(temp[i], i + 1)


func load_options() -> void:
	if not FileAccess.file_exists(SAVE_USERNAMES_PATH):
		return
	
	var file: FileAccess = FileAccess.open(SAVE_USERNAMES_PATH, FileAccess.READ)
	
	if file.get_error() != OK:
		OS.alert("Error when loading the last used usernames: " + error_string(file.get_error()))
	else:
		var text: String = file.get_as_text()
		var data_type: Variant = JSON.parse_string(text)
		var type: int = typeof(data_type)
		
		if type == TYPE_ARRAY:
			var data: Array = data_type
			for i in data:
				last_usernames.append(str(i))
		else:
			OS.alert("Error when parsing the last usernames")
	
	file.close()


func save_new_option(n_username: String) -> void:
	last_usernames.append(n_username)
	
	if last_usernames.size() > 5:
		last_usernames.remove_at(0)
	
	var file: FileAccess = FileAccess.open(SAVE_USERNAMES_PATH, FileAccess.WRITE)
	
	if file.get_error() != OK:
		OS.alert("Error when loading the last used usernames: " + error_string(file.get_error()))
	else:
		var data: String = JSON.stringify(last_usernames)
		file.store_string(data)
	
	file.close()


func _on_Start_pressed():
	if _username.text.length() != 0:
		start_requested.emit(_username.text)

func _on_start_client_pressed() -> void:
	if _username.text.length() != 0:
		var m_ip: String = server_option.get_item_text(server_option.get_selected_id())
		save_new_option(_username.text)
		start_client.emit(_username.text, m_ip)



func _on_Settings_pressed():
	settings_requested.emit()


func _on_Exit_pressed():
	exit_requested.emit()


func _on_check_toggled(button_pressed):
	ProjectSettings.set_setting("solar_system/network/server", button_pressed)



func _on_last_usernames_item_selected(index: int) -> void:
	print("Index " + str(index))
	if index == -1 or index == 0:
		return
	
	var temp: PackedStringArray = last_usernames
	#temp.reverse()
	
	for i in range(temp.size()):
		if i + 1 == index:
			if not temp[i].is_empty():
				_username.text = temp[i]
			break
	


func _on_username_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == 1:
			pass
