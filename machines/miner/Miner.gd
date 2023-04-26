class_name Miner
extends MachineCharacter

class MineTaskData:
	var location: Vector2
	var planet_id:  int
	var location_id: int = -1

signal mineral_extracted(id, amount)

var _actions: Array[IActionsContext.ActionContext] = []

func _ready():
#	super._ready()
	
	var action := IActionsContext.ActionContext.new()
	action.name = "Move"
	action.function = _move_request
	_actions.append(action)

func set_mining(value: bool) -> void:
	pass


func _move_request() -> void:
	print("Doing move request")

func get_actions() -> Array[IActionsContext.ActionContext]:
	return _actions
