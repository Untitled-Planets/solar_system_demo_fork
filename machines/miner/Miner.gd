class_name Miner
extends MachineCharacter

class MineTaskData:
#	var location: Vector2
	var planet_id:  int
	var location_id: int = -1
	var machine_id: int = -1

signal mineral_extracted(id, amount)

var _actions: Array[IActionsContext.ActionContext] = []
#var _game: Game

func _ready():
	super._ready()
	_game = get_tree().get_nodes_in_group("game")[0]
	var action := IActionsContext.ActionContext.new()
	action.name = "Move"
	action.function = func(): _game.prepare_task(get_task("move"))
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "CM"
	action.function = func(): _game.cancel_task(get_id(), get_current_task().get_id())
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "Despawn"
	action.function = func(): _game.despawn_machine(get_id())
	_actions.append(action)
	

func set_mining(value: bool) -> void:
	pass


func _move_request() -> void:
	print("Doing move request")

func get_actions() -> Array[IActionsContext.ActionContext]:
	return _actions
