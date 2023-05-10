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
@export var _info: PickableInfo

var _planet : StellarBody
var _waypoint: Waypoint
var _current_task: ITask = null
var _id: int = -1


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
			get_tree().call_group("waypoint_hud", "add_waypoint", _waypoint)
	else:
		if _waypoint:
			_waypoint.queue_free()
			_waypoint = null

func get_max_speed() -> float:
	return _movement._speed

func pm_enabled(value: bool) -> void:
	configure_waypoint(value)
	
func _process(delta):
	if _current_task:
		_current_task.update(delta)
		if _current_task.get_finished() != ITask.Finished.NONE:
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
			_current_task = t
			_current_task.data = p_data
			_current_task.start()
			return OK
	push_error("Task {} not found".format(p_task_id))
	return ERR_INVALID_PARAMETER

func cancel_task(task_id: String) -> void:
	var t: ITask = get_task(task_id)
	if t:
		t.stop()
	else:
		push_warning("Task {} not found".format(task_id))
	

###########################
# IWorker end
###########################

func get_id() -> int:
	return _id

func set_id(p_value) -> void:
	_id = p_value

func get_pickable_info() -> PickableInfo:
	return _info
