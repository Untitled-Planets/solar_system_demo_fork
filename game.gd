class_name Game
extends Node3D




@onready var _solar_system: SolarSystem = $SolarSystem
@onready var _warehouse: Warehouse = $warehouse
@onready var _asset_inventory: AssetInventory = $SolarSystem/asset_inventory
@onready var _inventory: InventoryHUD = $SolarSystem/HUD/Inventory
@onready var _waypoint_hud: WaypointHUD = $SolarSystem/HUD/WaypointHUD

var _machine_selected: MachineCharacter = null

func _ready():
	Server.add_machine_requested.connect(_on_add_machine)
	Server.task_requested.connect(_on_task_rquested)
	Server.task_cancelled.connect(_on_task_cancelled)
	

func _process(delta):
	_process_input()

func _process_input() -> void:
	var w: Waypoint = _waypoint_hud.selected_waypoint
	if Input.is_action_just_pressed("select_object"):
		if _is_move_request(w):
			var to := get_click_position()
			machine_move(_machine_selected.get_path(), _machine_selected.position, to)
			pass
		elif _is_mine_request(w):
			machine_mine(_machine_selected.get_path(), w.location_id)
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

func _on_add_machine(_player_id: int, _machine_id: int, _planet_id: int, _location: SpawnLocation) -> void:
	var planet: StellarBody = _solar_system.get_reference_stellar_body()
	var spawn_point := planet.get_spawn_point()
	var asset: Node3D = _asset_inventory.generate_asset(0)
	var miner: Miner = asset as Miner
	if miner:
		planet.node.add_child(miner)
		miner.set_planet(planet)
		miner.global_position = spawn_point
		miner.configure_waypoint(_solar_system.is_planet_mode_enabled())
		miner.mineral_extracted.connect(_on_mineral_extracted)

#func _on_inventory_add_machine(machine_asset: int):
#	Server.miner_spawn(0, machine_id, _solar_system.get_reference_stellar_body_id(), null)


func _on_task_cancelled(machine_path_id: NodePath, task_id: String) -> void:
	var w: IWorker = get_node_or_null(machine_path_id)
	if w:
		w.cancel_task(task_id)

func _on_task_rquested(object_id: NodePath, task_id: String, p_data) -> void:
#	print("Requesting task: ", task_id)
	var worker: IWorker = get_node(object_id)
	if worker.do_task(task_id, p_data) != OK:
		push_error("Cannot execute task {}".format(task_id))

##############################
# Helper functions
##############################
func spawn_machine(machine_id: int) -> void:
	Server.miner_spawn(0, machine_id, _solar_system.get_reference_stellar_body_id(), SpawnLocation.new())
	
func machine_move(machine_path_id: NodePath, from, to) -> void:
	var machine: MachineCharacter = get_node(machine_path_id)
	var data := MoveMachineData.new()
	data.machine_speed = machine.get_max_speed()
	data.from = from
	data.to = to
	data.planet_radius = _solar_system.get_reference_stellar_body().radius
	Server.machine_move(machine_path_id, "move", data)
	_machine_selected = null

func machine_mine(machine_path_id: NodePath, to) -> void:
	var data := Miner.MineTaskData.new()
#	data.location = Util.position_to_unit_coordinates(waypoint.position)
	data.planet_id = _solar_system.get_reference_stellar_body_id()
	data.location_id = to
	Server.machine_mine(_machine_selected.get_path(), "mine", data)
	_machine_selected = null
	pass

func cancel_task(machine_path_id: NodePath, task_id: String) -> void:
	Server.cancel_task(machine_path_id, task_id)

##############################
# End Helper functions
##############################
