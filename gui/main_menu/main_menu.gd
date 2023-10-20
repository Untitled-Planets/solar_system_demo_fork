extends Control


signal start_requested(username: String)
signal start_client(username: String, server_ip: String)
signal settings_requested
signal exit_requested

@onready var _username: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/username
@onready var multiplayer_server_ip: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer3/LineEdit


func _ready() -> void:
	_username.text = "character_" + str(randi() % 10)


#func _ready():
#	ProjectSettings.set_setting("solar_system/network/server", $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer2/check.button_pressed)

func _on_Start_pressed():
	if _username.text.length() != 0:
		start_requested.emit(_username.text)

func _on_start_client_pressed() -> void:
	if _username.text.length() != 0:
		var m_ip: String = multiplayer_server_ip.text
		
		start_client.emit(_username.text, m_ip)



func _on_Settings_pressed():
	settings_requested.emit()


func _on_Exit_pressed():
	exit_requested.emit()


func _on_check_toggled(button_pressed):
	ProjectSettings.set_setting("solar_system/network/server", button_pressed)

