class_name Miner
extends MachineCharacter

signal resource_collected(resource_type, resource_amount)

class MineTaskData:
#	var location: Vector2
	var planet_id:  int
	var location_id: int = -1
	var machine_id: int = -1

signal mineral_extracted(id, amount)

#@onready var _resource_producer : ResourceProducer = $resource_producer

var _actions: Array[IActionsContext.ActionContext] = []
var _mining_amount: int = 0


func _ready():
	super._ready()
	_game = get_tree().get_first_node_in_group(&"game")
	var action := IActionsContext.ActionContext.new()
	action.name = "Move"
	action.function = func(): _game.prepare_task(get_task("move"), get_id())
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "CM" # Cancel Movement
	action.function = func(): _game.cancel_task(get_id(), get_current_task().get_id())
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "Despawn"
	action.function = func(): _game.despawn_machine(get_id())
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "Mine"
	action.function = func(): _game.machine_mine(get_id())
	_actions.append(action)
	
	action = IActionsContext.ActionContext.new()
	action.name = "CMine" # Cancel Mine
	action.function = func(): _game.cancel_task(get_id(), get_current_task().get_id())
	_actions.append(action)
	
	#_game.sola
	
	#if $RayCast3D.is_colliding():
	#	var point: Vector3 = $RayCast3D.get_collision_point()
	#	global_position = point


func _process(delta: float):
	super._process(delta)


#func grab(p_amount: float):
#	return _resource_producer.grab(p_amount)

func set_mining(_value: bool) -> void:
	pass


func _move_request() -> void:
	print("Doing move request")

func get_actions() -> Array[IActionsContext.ActionContext]:
	return _actions

func get_mining_speed() -> int:
	return _mining_amount

func set_machine_data(p_data: Dictionary) -> void:
	super.set_machine_data(p_data)
	_mining_amount = p_data.mining_speed


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"character"):
		var miner_hud = get_tree().get_first_node_in_group(&"miner_hud")
		if miner_hud:
			miner_hud.show()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group(&"character"):
		var miner_hud: Control = get_tree().get_first_node_in_group(&"miner_hud")
		if miner_hud:
			miner_hud.hide()
