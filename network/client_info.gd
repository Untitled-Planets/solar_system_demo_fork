extends RefCounted
class_name ClientInfo


func _init() -> void:
	pass



func serialize() -> Dictionary:
	return {}



func deserialize(data: Dictionary) -> ClientInfo:
	assert(_has_valid_data_keys(data))
	return ClientInfo.new()


func _has_valid_data_keys(dic: Dictionary) -> bool:
	return true
