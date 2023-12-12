extends Control

@onready var line: LineEdit = $PanelContainer/VBoxContainer/HBoxContainer/LineEdit
@onready var chat: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var controls: Control = $PanelContainer/VBoxContainer/HBoxContainer
@onready var timer: Timer = $HideTimeout

func _ready() -> void:
	hide()
	controls.hide()
	add_to_group(&"chat_hud")
	MultiplayerServer.chat_message.connect(_on_message_recived)

func is_active() -> bool:
	return controls.visible

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and visible and not timer.is_stopped():
		visible = false
		
		if controls.visible:
			controls.hide()
	if event.is_action_pressed(&"toggle_chat"):
		visible = not visible
		
		if visible:
			controls.show()


func add_message(message: String, username: String) -> void:
	chat.append_text(username + ": " + message.trim_prefix(" ").trim_suffix(" ") + "\n")


func _on_message_recived(message: String, username: String) -> void:
	if not visible:
		if timer.is_stopped():
			timer.stop()
		timer.start()
	add_message(message, "[color=blue]" + username + "[/color]")


func _on_line_edit_text_submitted(new_text: String) -> void:
	line.text = ""
	new_text = new_text.trim_prefix(" ").trim_suffix(" ")
	
	if new_text.length() == 0:
		return
	
	add_message(new_text, "[color=yellow]" + get_username() + "[/color]")
	MultiplayerServer.send_chat_message(new_text)


func get_username() -> String:
	return "You"

func _on_button_pressed() -> void:
	_on_line_edit_text_submitted(line.text)
	controls.hide()


func _on_hide_timeout_timeout():
	visible = false
