extends RefCounted
class_name SyncBufferData

var timestamp: int
var _entities: Dictionary


func _init(timestamp: int, entities: Dictionary) -> void:
	self.timestamp = timestamp
	self._entities = entities


func has_network_object(network_object_id: int) -> bool:
	return _entities.has(network_object_id)


func entities_list_ids() -> PackedInt32Array:
	var arr: PackedInt32Array = []
	var k: Array = _entities.keys()
	var s: int = k.size()
	arr.resize(s)
	
	for i in range(s):
		arr[i] = int(k[i])
	
	return arr


func get_networks_ids() -> PackedInt64Array:
	var k: Array = _entities.keys()
	var s: int = k.size()
	var arr: PackedInt64Array = []
	
	arr.resize(s)
	
	for i in range(s):
		arr[i] = k[i]
	
	return arr


func get_object_data(network_object_id: int) -> Dictionary:
	if not has_network_object(network_object_id):
		return {}
	return _entities[network_object_id]



