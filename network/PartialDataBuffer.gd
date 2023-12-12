extends RefCounted
class_name PartialDataBuffer

var packed_count: int
var packets: PackedStringArray
var buffer_id: String
var _builded_dic: Dictionary = {}

func _init(count: int) -> void:
	packed_count = count
	packets = []
	packets.resize(count)


func is_finished() -> bool:
	var c: int = 0
	
	for i in packets:
		if not i.is_empty():
			c += 1
	
	return c == packets.size()

func update(idx: int, packet: String) -> void:
	packets[idx] = packet


func build() -> Error:
	if not is_finished():
		return ERR_PARAMETER_RANGE_ERROR
	var str: String = ""
	for s in packets:
		str += s
	_builded_dic = JSON.parse_string(str)
	
	return OK


func get_build() -> Dictionary:
	return _builded_dic

