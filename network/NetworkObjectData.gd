extends RefCounted
class_name NetworkObjectData

var _object_node: NetworkEntity


func _init(node: NetworkEntity = null) -> void:
	_object_node = node

func set_network_id(id: int) -> void:
	assert(_object_node != null)
	_object_node._network_object_id = id

func get_network_id() -> int:
	if _object_node == null:
		return -1
	
	return _object_node._network_object_id


func get_network_entity() -> NetworkEntity:
	assert(_object_node != null)
	return _object_node

func is_name(n: StringName) -> bool:
	assert(_object_node != null)
	return _object_node.name == n


func request_duplicate(flags: int = 15) -> NetworkEntity:
	return _object_node.duplicate(flags)


func serialize() -> Dictionary:
	assert(_object_node != null, "")
	return {
		"node_name": _object_node.name,
		"origin_control": _object_node.origin_control
	}
