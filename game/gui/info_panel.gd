class_name InfoPanel
extends Control

@onready var _texture_rect: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/CenterContainer/Preview
@onready var _info: Label = $PanelContainer/MarginContainer/HBoxContainer/CenterContainer2/Label

func set_info(p_info: PickableInfo) -> void:
	if p_info == null:
		_clean()
	else:
		_texture_rect.texture = p_info.texture
		_info.text = p_info.info

func _clean() -> void:
	_texture_rect.texture = null
	_info.text = "";
