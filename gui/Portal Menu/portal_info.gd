extends RefCounted
class_name PortalInfo


var spawn_ship_position: Vector3
var catalog: Array[Dictionary] = []

func _init(spawn_position: Vector3, catalog_list: Array[Dictionary] = []) -> void:
	spawn_ship_position = spawn_position
	catalog = catalog_list
