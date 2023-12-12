extends RefCounted
class_name BitField

const MAX_SEGMENT_SIZE: int = 16

var size: int
var fields: PackedInt64Array

func _init(p_size: int) -> void:
	size = p_size
	
	fields = PackedInt64Array()
	fields.resize(ceili(size / MAX_SEGMENT_SIZE))


func _to_string() -> String:
	return "Segment size: " + str(MAX_SEGMENT_SIZE) + " - Fields: \n" + str(fields)


func get_bit_state(idx: int) -> bool:
	assert(idx >= 0 or idx < size)
	
	var idxElement: int = floori(idx / MAX_SEGMENT_SIZE)
	var bitIdx: int = idx % MAX_SEGMENT_SIZE
	
	var element: int = fields[idxElement]
	return (element >> bitIdx) & 1


func set_bit_state(idx: int, state: bool) -> void:
	assert(idx >= 0 or idx < size)
	
	var idxElement: int = floori(idx / MAX_SEGMENT_SIZE)
	var bitIdx: int = idx % MAX_SEGMENT_SIZE
	
	if state:
		fields[idxElement] |= 1 << bitIdx
	else:
		fields[idxElement] &= ~(1 << bitIdx)
	
