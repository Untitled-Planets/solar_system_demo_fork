extends Node


@export var _demo_material: PackedScene = null

@warning_ignore("unused_private_class_variable")
var _materials: Dictionary = {}
@warning_ignore("unused_private_class_variable")
var _instances: Dictionary = {}



func _ready():
	pass


func spawn_material(_p_material_type: int, p_material_uuid: String) -> PickableObject:
	var instance = _demo_material.instantiate()
	instance.uuid = p_material_uuid
	return instance
