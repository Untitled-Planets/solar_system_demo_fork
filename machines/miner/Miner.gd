class_name Miner
extends MachineCharacter

class MineTaskData:
	var location: Vector2
	var planet_id:  int

signal mineral_extracted(id, amount)

func set_mining(value: bool) -> void:
	pass
