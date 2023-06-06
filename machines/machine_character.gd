class_name MachineCharacter
extends IWorker

enum State {
	WORKING,
	MOVING,
	IDLE,
	MINING,
}

@onready var _movement: MachineMovement = $movement
@onready var _tasks_node: Node = $tasks

@export var _waypoint_scene: PackedScene
@export var _machine_view: Texture

#var _info: PickableInfo
var _planet : StellarBody
var _waypoint: Waypoint
var _movement_target_waypoint: Waypoint
var _current_task: ITask = null
var _id: int = -1
var _game: Game
var _owner: String
var _is_focussed: bool = false

var _task_data_queue: Array = []

func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]
	

func go_to(location: Vector3) -> void:
	_movement.go_to(location)

func set_planet(p : StellarBody) -> void:
	_planet = p

func get_planet() -> StellarBody:
	return _planet

func is_owner() -> bool:
	return true

func is_server() -> bool:
	return true

func configure_waypoint(value: bool) -> void:
	if value:
		_waypoint = _waypoint_scene.instantiate()
		_waypoint.info = "Machine name: {}".format([name], "{}")
		add_child(_waypoint)
		if ProjectSettings.get_setting("solar_system/debug/show_machine_waypoint"):
			_waypoint.set_enable_debug_mesh(true)
			_waypoint.scale_area(30)
#			get_tree().call_group("waypoint_hud", "add_waypoint", _waypoint)
	else:
		if _waypoint:
			_waypoint.queue_free()
			_waypoint = null

func get_waypoint()-> Waypoint:
	return _waypoint

func get_max_speed() -> float:
	return _movement._speed

func pm_enabled(value: bool) -> void:
	configure_waypoint(value)
	
func _process(delta):
	if _current_task:
		_current_task.update(delta)
		if _current_task.get_finished() == ITask.Finished.SUCCESS:
			if _current_task.get_task_name() == "move":
				WaypointManager.remove_waypoint(_movement_target_waypoint)
				_movement_target_waypoint.queue_free()
				_movement_target_waypoint = null
			_game.finish_task(get_id(), _current_task.get_id())
			_current_task = null
			


###########################
# IWorker
###########################

func get_task(task_id: String) -> ITask:
	var tasks = get_tasks()
	var t: ITask = null
	for task in tasks:
		if task.get_task_name() == task_id:
			t = task
			break
	return t

func get_tasks() -> Array[ITask]:
	var children := _tasks_node.get_children()
	var a: Array[ITask] = []
	a.resize(children.size())
	for index in children.size():
		a[index] = children[index] as ITask
	return a

func get_current_task() -> ITask:
	return _current_task

func do_task(p_task_id: String, p_data) -> int:
	for t in get_tasks():
		if t.get_task_name() == p_task_id:
			if p_task_id == "move":
				_configure_moevment_target_waypoint(Vector2(p_data.to.x, p_data.to.y), p_data.planet_radius)
			_current_task = t
			_current_task.data = p_data
			_current_task.set_id(p_data.task_id)
			_current_task.start()
			return OK
	push_error("Task {} not found".format(p_task_id))
	return ERR_INVALID_PARAMETER

func _configure_moevment_target_waypoint(p_unit_coordinate: Vector2, planet_radius: float):
	_movement_target_waypoint = _waypoint_scene.instantiate()
	var node := _game.get_solar_system().get_reference_stellar_body().node
	node.add_child(_movement_target_waypoint)
	_movement_target_waypoint.global_position = Util.unit_coordinates_to_unit_vector(p_unit_coordinate) * planet_radius

func cancel_task(task_id: int) -> void:
	if _current_task and _current_task.get_id() == task_id:
		_current_task.stop()

func set_task_batch(p_batch: Array) -> void:
	if p_batch.size() == 0:
		return
	
	var current_task_data = p_batch[0]
	do_task(current_task_data.task_name, current_task_data.data)
	_current_task.set_id(current_task_data.task_id)
	_current_task.set_started_time_delta(current_task_data.started_delta)

###########################
# IWorker end
###########################

func get_id() -> int:
	return _id

func set_id(p_value) -> void:
	_id = p_value


func set_owner_id(p_owner_id) -> void:
	_owner = p_owner_id

func get_pickable_info() -> PickableInfo:
	var info := PickableInfo.new()
	info.type = "machine"
	info.name = name
	info.meta = {
		owner = _owner,
		texture = _machine_view,
		current_task_name = _current_task.get_task_name() if _current_task != null else ""
	}
	return info

func set_focus(p_value: bool) -> void:
	_is_focussed = p_value

func is_focussed() -> bool:
	return _is_focussed

func destroy_machine():
	WaypointManager.remove_waypoint(_waypoint)
	queue_free()

func get_color() -> Color:
	if _current_task != null:
		return Color.BLUE
	return Color.WHITE

#func _exit_tree():
#	WaypointManager.remove_waypoint(_waypoint)
