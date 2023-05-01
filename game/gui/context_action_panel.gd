class_name ContextActionPanel
extends Control

@onready var _pivot: GridContainer = $PanelContainer/MarginContainer/Pivot

@export var _button_scene: PackedScene

func _ready() -> void:
	pass

# IActionContext
func set_context(p_context_action) -> void:
	_clean()
	_fill_options(p_context_action.get_actions())


func _fill_options(p_actions: Array[IActionsContext.ActionContext]) -> void:
	for action in p_actions:
		var instance = _button_scene.instantiate()
		instance.set_context(action)
		_pivot.add_child(instance)

func _clean() -> void:
	for child in _pivot.get_children():
		child.queue_free()
