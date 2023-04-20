class_name Warehouse
extends Node

class ItemData:
	var id: int = -1
	var amount: float = 0.0
	
	func _init(p_id, p_amount):
		id = p_id
		amount = p_amount

var _store: Dictionary = {}

func add_item(p_data: ItemData) -> void:
	if not _store.has(p_data.id):
		_store[p_data.id] = 0
	_store[p_data.id] += p_data.amount



func get_store() -> Dictionary:
	return _store.duplicate()
