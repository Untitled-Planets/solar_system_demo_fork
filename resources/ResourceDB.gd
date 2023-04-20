class_name ResourceDB
extends Node

@export var _planet_resources: Array[PlanetResource]

func _ready():
	pass


func get_planet_resource_ids() -> Array[int]:
	var ids: Array[int] = []
	ids.resize(_planet_resources.size())
	for index in ids.size():
		ids[index] = _planet_resources[index].id
	return ids

func get_planet_resource_by_id(p_id: int) -> PlanetResource:
	for r in _planet_resources:
		if r.id == p_id:
			return r
	return null
