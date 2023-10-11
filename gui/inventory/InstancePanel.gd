class_name InstancePanel
extends MarginContainer

signal instance_selected(asset_id)

@onready var _label: Label = $Panel/Label

@export var _id: int = -1

var _text: String
@export var text: String:
	set(value):
		_text = value
		if _label:
			_label.text = _text
		pass
	get:
		return _text


var _game: Game

func _ready():
	_label.text = _text

func set_id(p_id: int) -> void:
	_id = p_id

func get_id() -> int:
	return _id

func _on_texture_button_pressed():
	print("Instance selected") 
	if _id != -1:
		emit_signal("instance_selected", self)

func _spawn_machine() -> void:
	pass#Server.machine

func get_actions() -> Array[IActionsContext.ActionContext]:
	var spawn_action := IActionsContext.ActionContext.new()
	spawn_action.name = "s"
	spawn_action.function = func(): _game.spawn_machine(_id)
	return [spawn_action]


func set_game_ref(p_game: Game) -> void:
	_game = p_game
