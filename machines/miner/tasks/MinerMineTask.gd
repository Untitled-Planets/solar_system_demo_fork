class_name MinerMineTask
extends AMinerTask

var _status: int = ITask.Finished.NONE

var _data: Miner.MineTaskData
var _target_location: Vector3
var _is_on_place: bool = false

func _ready():
	_movement.move_request_finished.connect(_on_move_finished)

func start() -> void:
	super.start()
	_data = data
	_target_location = Util.unit_coordinates_to_unit_vector(_data.location) * _miner.get_planet().radius

func _update_task(delta: float) -> void:
#	var distance := Util.distance_on_sphere(_target_location.length(), _target_location, _miner.position)
#	if distance > 10:
	if not _is_on_place:
		if not _movement.is_moving():
			var d := MoveMachineData.new()
			d.to = _target_location
			d.from = _miner.position
			d.machine_speed = _miner.get_max_speed()
			d.planet_radius = _miner.get_planet().radius
			_movement.move_request(d)
	else:
		_miner.set_mining(true)

func get_finished() -> int:
	return _status


func _on_move_finished(request_id: int) -> void:
	_is_on_place = true
	pass
