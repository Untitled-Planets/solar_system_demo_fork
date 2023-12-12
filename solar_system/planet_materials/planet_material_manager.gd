extends Node


@export var _demo_material: PackedScene = null


func spawn_material(_p_material_type: int, p_material_uuid: int) -> PickableObject:
	var instance = _demo_material.instantiate()
	instance.id = p_material_uuid
	return instance
