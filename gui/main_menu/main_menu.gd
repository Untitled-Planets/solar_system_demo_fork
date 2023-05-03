extends Control


signal start_requested(username: String)
signal settings_requested
signal exit_requested

@onready var _username: LineEdit = $VBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/HBoxContainer/username


func _on_Start_pressed():
	if _username.text.length() != 0:
		start_requested.emit(_username.text)


func _on_Settings_pressed():
	settings_requested.emit()


func _on_Exit_pressed():
	exit_requested.emit()
