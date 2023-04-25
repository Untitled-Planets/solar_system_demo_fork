class_name MinerMineTask
extends AMinerTask

var _status: int = ITask.Finished.NONE
var _data: Miner.MineTaskData
var _target_location: Vector3
var _is_on_place: bool = false
var _game: Game

@export var _mine_interval: float = 1.0
var _mine_acc: float = 0.0

func _ready():
	_movement.move_request_finished.connect(_on_move_finished)
	Server.planet_resource_collected.connect(_on_resource_collected)
#	_game = get_tree().get_nodes_in_group("game")[0]

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
		_mine_acc += delta
		if _mine_acc > _mine_interval:
			Server.machine_collect_resource(_miner.get_path(), _data.planet_id, _data.location_id)
			_mine_acc = 0.0
		_miner.set_mining(true)

func get_finished() -> int:
	return _status


func _on_move_finished(request_id: int) -> void:
	_is_on_place = true


func _on_resource_collected(machine_id: NodePath, planet_id, amount: int) -> void:
	print("Collected amount: ", amount)
	if _miner.get_path() == machine_id:
		if amount == 0:
			print("Mining completed...")
			_status = ITask.Finished.SUCCESS
