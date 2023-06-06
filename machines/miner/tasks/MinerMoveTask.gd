class_name MinerMoveTask
extends AMinerTask

var _status: int = ITask.Finished.NONE
var _data: MoveMachineData
var _target_location: Vector3
var _is_on_place: bool = false
var _game: Game

@export var _mine_interval: float = 1.0
var _mine_acc: float = 0.0

func _ready():
	pass

func start() -> void:
	super.start()
	_status = ITask.Finished.NONE
	_movement.move_request_finished.connect(_on_move_finished)
	_is_on_place = false
	var d := MoveMachineData.new()
	d.from = Vector2(data.from.x, data.from.y)
	d.to = Vector2(data.to.x, data.to.y)
	d.planet_radius = data.planet_radius
	d.machine_speed = data.machine_speed
	_data = d
	if not _task_cancelled:
		if not _movement.is_moving():
			_movement.move_request(_data)

func _update_task(delta: float) -> void:
	if _is_on_place:
		_status = Finished.SUCCESS
	

func get_finished() -> int:
	return _status


func _on_move_finished(request_id: int) -> void:
	_movement.move_request_finished.disconnect(_on_move_finished)
	_is_on_place = true


func _on_resource_collected(machine_id: NodePath, planet_id, amount: int) -> void:
	if _miner.get_path() == machine_id:
		if amount == 0:
			_status = ITask.Finished.SUCCESS

func resume_task(p_task_data: Dictionary) -> void:
	data = p_task_data
	pass

func set_started_time_delta(p_started_time: float):
	_movement.set_total_time(p_started_time)

func stop() -> void:
	super.stop()
	_is_on_place = false
	_status = ITask.Finished.NONE
	_movement.move_request_finished.disconnect(_on_move_finished)
	_movement.cancel_move_request(null)
