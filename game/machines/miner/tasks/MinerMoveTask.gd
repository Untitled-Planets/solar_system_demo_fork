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
	
	_movement.move_request_finished.connect(_on_move_finished)
	_is_on_place = false
	_data = data
	if not _task_cancelled:
		if not _movement.is_moving():
			_movement.move_request(_data)
#	_target_location = Util.unit_coordinates_to_unit_vector(_data.location) * _miner.get_planet().radius
	

func _update_task(delta: float) -> void:
#	var distance := Util.distance_on_sphere(_target_location.length(), _target_location, _miner.position)
#	if distance > 10:
	if _is_on_place:
		_status = Finished.SUCCESS

func get_finished() -> int:
	return _status


func _on_move_finished(request_id: int) -> void:
	_movement.move_request_finished.disconnect(_on_move_finished)
	_is_on_place = true


func _on_resource_collected(machine_id: NodePath, planet_id, amount: int) -> void:
#	print("Collected amount: ", amount)
	if _miner.get_path() == machine_id:
		if amount == 0:
			print("Mining completed...")
			_status = ITask.Finished.SUCCESS


func stop() -> void:
	super.stop()
	_movement.cancel_move_request(null)
