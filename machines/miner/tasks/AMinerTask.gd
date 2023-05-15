class_name AMinerTask
extends ITask

@onready var _miner: Miner = get_parent().get_parent()
@onready var _movement: MachineMovement = get_parent().get_parent().get_node("movement")

var _task_started: bool = false
var _task_cancelled: bool = false
var data

var _id: int = -1

func _ready():
	_task_started = false


func update(delta: float):
	if _task_started:
		_update_task(delta)

func _update_task(delta: float) -> void:
	pass

func start() -> void:
	_task_started = true
	_task_cancelled = false


func puase() -> void:
	_task_started = false

func stop() -> void:
	_task_started = false
	_task_cancelled = true

func get_id() -> int:
	return _id
