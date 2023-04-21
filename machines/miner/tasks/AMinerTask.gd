class_name AMinerTask
extends ITask

@onready var _miner: Miner = get_parent().get_parent()
@onready var _movement: MachineMovement = get_parent().get_parent().get_node("movement")

var _task_started: bool = false
var data


func _ready():
	_task_started = false


func update(delta: float):
	if _task_started:
		_update_task(delta)
	pass

func _update_task(delta: float) -> void:
	pass

func start() -> void:
	_task_started = true


func puase() -> void:
	_task_started = false

func stop() -> void:
	_task_started = false
