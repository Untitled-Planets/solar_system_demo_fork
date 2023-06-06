class_name InfoPanel
extends Control

@onready var _texture_rect: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/CenterContainer/Preview
@onready var _info: Label = $PanelContainer/MarginContainer/HBoxContainer/CenterContainer2/Label

func set_info(p_info: PickableInfo) -> void:
	if p_info == null:
		_clean()
	else:
		_texture_rect.texture = p_info.meta.texture
		var task_name: String = p_info.meta.current_task_name
		if task_name == "":
			task_name = "None"
		var t: String = "Name: {0}\ncurrent task: {1}\nOwner: {2}".format([p_info.name, task_name, p_info.meta.owner])
		_info.text = t

func _clean() -> void:
	_texture_rect.texture = null
	_info.text = "";
