class_name Game
extends Node3D




@onready var _solar_system: SolarSystem = $SolarSystem
@onready var _warehouse: Warehouse = $warehouse
@onready var _asset_inventory: AssetInventory = $SolarSystem/asset_inventory
@onready var _inventory: InventoryHUD = $SolarSystem/HUD/Inventory
@onready var _waypoint_hud: WaypointHUD = $SolarSystem/HUD/WaypointHUD

@export var WaypointScene: PackedScene = null

var _machine_selected: MachineCharacter = null
var _machines := {}
var _username := ""

func _ready():
	Server.add_machine_requested.connect(_on_add_machine)
	Server.task_cancelled.connect(_on_task_cancelled)
	Server.planet_status_requested.connect(_on_planet_status_requested)
	Server.execute_task_requested.connect(_on_task_requested)
	_solar_system.reference_body_changed.connect(_on_reference_body_changed)
	

func _process(delta):
	_process_input()

func _process_input() -> void:
	var w: Waypoint = _waypoint_hud.selected_waypoint
	if Input.is_action_just_pressed("select_object"):
		if _is_move_request(w):
			var to := get_click_position()
			machine_move(_machine_selected.get_id(), _machine_selected.position, to)
			pass
		elif _is_mine_request(w):
			machine_mine(_machine_selected.get_id(), w.location_id)
		else:
			if w:
				_on_waypoint_hud_waypoint_selected(w)

func get_solar_system() -> SolarSystem:
	return _solar_system


func get_click_position() -> Vector3:
	var state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.new()
	var camera: Camera3D = get_viewport().get_camera_3d()
	var origin := camera.project_ray_origin(get_viewport().get_mouse_position())
	var dir := camera.project_ray_normal(get_viewport().get_mouse_position())
	query.from = origin
	query.to = origin + dir * 9999
	var result := state.intersect_ray(query)
	if not result.is_empty():
		return result.position
	return Vector3.ZERO

func _is_move_request(p_waypoint: Waypoint) -> bool:
	return _machine_selected and not p_waypoint

func _is_mine_request(p_waypoint: Waypoint) -> bool:
	return _machine_selected and p_waypoint

func _on_waypoint_hud_waypoint_selected(waypoint: Waypoint):
	var so = waypoint.get_selected_object()
	if so is MachineCharacter and not _machine_selected:
		_machine_selected = so
		_update_action_panel()
	_update_info(so)

func _update_action_panel() -> void:
	if _machine_selected:
		_inventory.set_actions(_machine_selected)
	pass

func _update_info(p_obj) -> void:
	if p_obj.has_method("get_pickable_info"):
		_inventory.set_info(p_obj.get_pickable_info())
	else:
		_inventory.set_info(null);

func _on_mineral_extracted(id, amount) -> void:
	_warehouse.add_item(Warehouse.ItemData.new(id, amount))

func _on_reference_body_changed(body_info):
	var previous_body := _solar_system.get_reference_stellar_body_by_id(body_info.old_id)
	previous_body.remove_machines()
	get_planet_status()

func _on_planet_status_requested(solar_system_id, planet_id, data):
	var machines  = data.machines
	var planet: StellarBody = _solar_system.get_reference_stellar_body_by_id(planet_id)
	for md in machines:
		_on_add_machine(_username, planet_id, md.asset_id, md.id)
		var m: MachineCharacter = _machines[int(md.id)]
		m.set_task_batch(md.tasks) 
		var final_position = Util.unit_coordinates_to_unit_vector(Vector2(md.location.x, md.location.y)) * planet.radius
		m.global_position = final_position
	load_waypoints()

func _on_add_machine(_player_id: String, _planet_id: int, machine_asset_id: int, machine_instance_id: int) -> void:
	var asset: Node3D = _asset_inventory.generate_asset(machine_asset_id)
	_machines[machine_instance_id]  = asset
	var planet: StellarBody = _solar_system.get_reference_stellar_body()
	var spawn_point := planet.get_spawn_point()
	var miner: Miner = asset as Miner
	if miner:
		miner.set_id(machine_instance_id)
		planet.add_machine(miner)
		miner.set_planet(planet)
		miner.global_position = spawn_point
		miner.configure_waypoint(_solar_system.is_planet_mode_enabled())
		miner.mineral_extracted.connect(_on_mineral_extracted)


func _on_task_cancelled(solar_system_id: int, planet_id: int, machine_id: int, task_id: int, requester_id: String) -> void:
	var w: IWorker = _machines.get(machine_id, null)
	if w:
		w.cancel_task(task_id)

func _on_task_requested(solar_system_id: int, planet_id: int, machine_id: int, requester_id: String, p_task_data: Dictionary) -> void:
#	print("Requesting task: ", task_id)
	if not _machines.has(machine_id):
		return
	
	var worker: IWorker = _machines[machine_id]
	if worker.do_task(p_task_data.task_name, p_task_data) != OK:
		push_error("Cannot execute task {}".format(p_task_data.task_id))


func load_waypoints():
	var deposits = Server.planet_get_deposits(_solar_system.get_reference_stellar_body_id())
#	var ss := _get_solar_system()
	for index in deposits.size():
		var mine = deposits[index]
		var waypoint: Waypoint = WaypointScene.instantiate()
		var planet := _solar_system.get_reference_stellar_body()
#		waypoint.transform = planet.get_surface_transform(mine.pos)
		waypoint.location = mine.pos
		waypoint.info = "Mine pos: {}\nAmount: {}".format([mine.pos, mine.amount], "{}")
		waypoint.location_id = index
		planet.node.add_child(waypoint)
		planet.waypoints.append(waypoint)
		waypoint.global_position = Util.coordinate_to_unit_vector(mine.pos) * planet.radius
##############################
# Helper functions
##############################
func spawn_machine(machine_id: int) -> void:
	Server.miner_spawn(0, _solar_system.get_reference_stellar_body_id(), _username, machine_id)
	
func machine_move(machine_id: int, from, to) -> void:
	if not _machines.has(machine_id):
		return
	var machine: MachineCharacter = _machines[machine_id]
	var data := MoveMachineData.new()
	data.machine_speed = machine.get_max_speed()
	data.from = Util.position_to_unit_coordinates(from)
	data.to = Util.position_to_unit_coordinates(to)
	data.planet_radius = _solar_system.get_reference_stellar_body().radius
	Server.machine_move(0, _solar_system.get_reference_stellar_body_id(), machine_id, _username, "move", data)
	_machine_selected = null

# TODO remove position. This should be gathered from server.
func machine_mine(p_machine_id: int, p_to: int) -> void:
	var data := Miner.MineTaskData.new()
	data.planet_id = _solar_system.get_reference_stellar_body_id()
	print("Sending location ID: {0}".format([p_to]))
	data.location_id = p_to
	data.machine_id = _machine_selected.get_id()
	print("Sending Going to: {0}".format([Util.coordinate_to_unit_coordinates(Server.get_deposit_coordinate(0, get_solar_system().get_reference_stellar_body_id(), p_to))]))
	Server.machine_mine(0, get_solar_system().get_reference_stellar_body_id(), _machine_selected.get_id(), _username, "mine", data)
	_machine_selected = null

func cancel_task(machine_id: int, task_id: int) -> void:
	Server.cancel_task(0, get_solar_system().get_reference_stellar_body_id(), machine_id, task_id, _username)

func finish_task(machine_id: int, task_id: int) -> void:
	Server.finish_task(0, get_solar_system().get_reference_stellar_body_id(), machine_id, task_id, _username)


func get_planet_status() -> void:
	Server.get_planet_status(1, 0, _solar_system.get_reference_stellar_body_id())
##############################
# End Helper functions
##############################


func _on_solar_system_loading_progressed(info):
	if info.finished:
		Server.get_machine_assets(_username)
