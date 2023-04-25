class_name AssetPanel
extends MarginContainer

signal asset_selected(asset_id)

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


func _ready():
	_label.text = _text

func _on_texture_button_pressed():
	if _id != -1:
		emit_signal("asset_selected", _id)
