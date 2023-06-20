class_name MinerMineTask
extends AMinerTask

var _status: int = ITask.Finished.NONE
var _data: Miner.MineTaskData
var _target_coordinate: Vector2
var _is_on_place: bool = false
var _game: Game

@export var _mine_interval: float = 1.0
var _mine_acc: float = 0.0

func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]
	Server.planet_resource_collected.connect(_on_resource_collected)

func start() -> void:
	super.start()
	var d := Miner.MineTaskData.new()
	d.location_id = data.location_id
	d.planet_id = data.planet_id
	_data = d
	var coordinate: Vector2 = Server.get_deposit_coordinate(0, _game.get_solar_system().get_reference_stellar_body_id(), d.location_id)
	_target_coordinate = Util.coordinate_to_unit_coordinates(coordinate)
	_is_on_place = true
	_movement.move_request_finished.connect(_on_move_finished)
	

func _update_task(delta: float) -> void:
	if not _task_cancelled:
		if not _is_on_place:
			if not _movement.is_moving():
				var d := MoveMachineData.new()
				d.from = Util.position_to_unit_coordinates(_miner.position)
				d.to = _target_coordinate
				d.machine_speed = _miner.get_max_speed()
				d.planet_radius = _miner.get_planet().radius
				_movement.move_request(d)
		else:
			_mine_acc += delta
			if _mine_acc > _mine_interval:
				Server.machine_collect_resource(0, _data.planet_id, _data.location_id, _miner.get_id(), _game.get_user_id(), _miner.get_mining_speed())
				_mine_acc = 0.0
			_miner.set_mining(true)


func get_finished() -> int:
	return _status


func _on_move_finished(request_id: int) -> void:
	_movement.move_request_finished.disconnect(_on_move_finished)
	_is_on_place = true


func _on_resource_collected(machine_id: int, planet_id, amount: int) -> void:
	if machine_id == _miner.get_id():
		if amount == 0:
			_status = ITask.Finished.SUCCESS
#			var t: ITask = _miner.get_current_task()
#			Server.finish_task(0, _data.planet_id, _miner.get_id(), _miner.get_current_task().get_id(), _game._username)


func resume_task(p_task_data: Dictionary) -> void:
	data = p_task_data
	pass

func set_started_time_delta(p_started_time: float):
#	_movement.set_total_time(p_started_time)
	Server.cosume_mine_amount_by_location_id(0, data.planet_id, data.location_id, p_started_time)
	pass



func stop() -> void:
	super.stop()
	_movement.cancel_move_request(null)
