@tool
class_name ActionButton
extends MarginContainer


signal action_requested(action_id)

@onready var _button: Button = $Button

@export var display_action: String:
	set(value):
		display_action = value
		if _button:
			_button.text = value

@export var _action_id: String


func _on_button_pressed():
	action_requested.emit(_action_id)
