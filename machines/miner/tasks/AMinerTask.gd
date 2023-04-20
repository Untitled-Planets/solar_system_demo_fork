class_name AMinerTask
extends ITask

@onready var _miner: Miner = get_parent().get_parent()

var _task_started: bool = false

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
