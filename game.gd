class_name Game
extends Node3D

signal machine_instance_from_ui_selected(machine_id: int)
signal exit_to_menu_requested


@onready var _solar_system: SolarSystem = $SolarSystem
@onready var _warehouse: Warehouse = $warehouse
@onready var _asset_inventory: AssetInventory = $asset_inventory
@onready var _inventory: InventoryHUD = $HUD/Inventory
@onready var _waypoint_hud: WaypointHUD = $HUD/WaypointHUD
@onready var _mouse_capture = $MouseCapture
@onready var _hud = $HUD
@onready var _pause_menu = $PauseMenu
@onready var _progress_bar: ProgressBar = $ProgressBar


@export var ShipController: PackedScene = null
@export var WaypointScene: PackedScene = null
@export var _mouse_action_texture: Texture = null
@export var CameraScene: PackedScene
@export var ShipScene: PackedScene
@export var CharacterScene: PackedScene
@export var LocalControllerScene: PackedScene
@export var RemoteControllerScene: PackedScene
@export var StationScene: PackedScene


var _machine_selected: MachineCharacter = null
var _machines := {}
var _username := ""
var _info_object = null
var _task_ui_from_node_selected: ITask = null
var _settings_ui : Control
var _avatar
var _ship = null
var _local_player: AController = null
var _players: Dictionary = {}

func _ready():
	Server.add_machine_requested.connect(_on_add_machine)
	Server.task_cancelled.connect(_on_task_cancelled)
	Server.execute_task_requested.connect(_on_task_requested)
	Server.despawn_machine_requested.connect(_on_despawn_machine_requested)
	_solar_system.reference_body_changed.connect(_on_reference_body_changed)
	machine_instance_from_ui_selected.connect(_on_machine_instance_from_ui_selected)
	Server.get_solar_system_data()
	_solar_system.loading_progressed.connect(_on_loading_progressed)
	MultiplayerServer.planet_status_requested.connect(_on_planet_status_requested)
	MultiplayerServer.resource_collection_started.connect(_on_resource_collection_started)
	MultiplayerServer.resource_collection_finished.connect(_on_resource_collection_finished)
	MultiplayerServer.resource_collection_progressed.connect(_on_resource_collection_progressed)
	MultiplayerServer.users_updated.connect(_on_users_updated)
	MultiplayerServer.user_position_updated.connect(_on_user_position_updated)
	MultiplayerServer.resources_generated.connect(_on_resources_generated)
	MultiplayerServer.floating_resources_updated.connect(_on_floating_resources_updated)
	MultiplayerServer.init()


func _on_resources_generated(p_solar_system_id, p_planet_id, p_resources):
	pass


func _on_user_position_updated(p_user_id: String, p_position):
	var c: RemoteController = _players.get(p_user_id, null)
	if c:
		c.set_remote_position(p_position)

func _on_users_updated(p_joinigin_users, p_leaving_users):
	for joining in p_joinigin_users:
		if _players.has(joining):
			continue
		
		var c: RemoteController = RemoteControllerScene.instantiate()
		var char: Character = await _spawn_player()
		char.set_controller(c)
		_players[joining] = c
		c.possess(char)
		add_child(c)
		_solar_system.add_child(char)
		c.set_uuid(joining)

func _on_resource_collection_started(p_resource_id):
	_progress_bar.visible = true

func _on_resource_collection_finished(p_resource_id):
	_progress_bar.visible = false

func _on_resource_collection_progressed(p_resource_id, p_unit_procent: float):
	_progress_bar.value = p_unit_procent

func _on_loading_progressed(p_progress_info):
	if p_progress_info.finished:
		_solar_system.set_reference_body(2)
		var controller: CharacterController = LocalControllerScene.instantiate()
		var avatar: Character = await _spawn_player()
		avatar.set_controller(controller)
		controller.possess(avatar)
		add_child(controller)
		_solar_system.add_child(avatar)
	#	avatar.network_id = p_player_id
#		var controller: CharacterController = avatar.get_controller()
		controller.set_uuid("")
		_local_player = controller as AController
		_mouse_capture.capture()
		# Camera must process before the ship so we have to spawn it before...
		var camera = CameraScene.instantiate()
		camera.auto_find_camera_anchor = true
		camera.set_target(avatar)
	#	if _settings.world_scale_x10:
	#		camera.far *= SolarSystemSetup.LARGE_SCALE
		_solar_system.add_child(camera)

func _spawn_player() -> Character:
	# Spawn player
	_hud.show()
	
	# Try to spawn avatar on the planet
	var avatar = null
	while avatar == null:
		await get_tree().process_frame
		
		var query := PhysicsRayQueryParameters3D.new()
		query.from = _solar_system.get_reference_stellar_body().radius * 10 * Vector3.UP
		query.to = Vector3.ZERO
		var state := get_world_3d().direct_space_state
		var result := state.intersect_ray(query)
		
		if not result.is_empty():
			avatar = CharacterScene.instantiate()
#			_solar_system.add_child(avatar)
			avatar.position = result.position
	
	return avatar


func _process(delta):
	_process_input()
	if _info_object:
		_update_info(_info_object)
	if _is_about_to_request_action():
		Input.set_custom_mouse_cursor(_mouse_action_texture, Input.CURSOR_ARROW, Vector2(24, 24))
	else:
		Input.set_custom_mouse_cursor(null)
	
	if _local_player:
		MultiplayerServer.send_last_position("dummy-id", _local_player.get_character().global_position)


func _is_about_to_request_action() -> bool:
	return _machine_selected != null

func _on_machine_instance_from_ui_selected(p_machine_id: int):
	_on_waypoint_hud_waypoint_selected(_machines[p_machine_id])
	_machine_selected.set_focus(true)


func _process_input() -> void:
	var w: Waypoint = _waypoint_hud.selected_waypoint
	if Input.is_action_just_pressed("no_context_select_object"):
		if w:
			_on_waypoint_hud_waypoint_selected(w.get_selected_object())
			_machine_selected = _info_object if _info_object is MachineCharacter else null
		elif _task_ui_from_node_selected and not w:
			var to := get_click_position()
			if _task_ui_from_node_selected.get_task_name() == "move":
				machine_move(_machine_selected.get_id(), _machine_selected.position, to)
				_task_ui_from_node_selected = null
				_machine_selected = null
	
	elif Input.is_action_just_pressed("select_object"):
		if _is_move_request(w):
			var to := get_click_position()
			machine_move(_machine_selected.get_id(), _machine_selected.position, to)
			pass
		elif _is_move_at_location_request(w):
			machine_move_at_location_id(_machine_selected.get_id(), w.location_id)
		else:
			if w:
				_on_waypoint_hud_waypoint_selected(w.get_selected_object())

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

func _is_move_at_location_request(p_waypoint: Waypoint) -> bool:
	return _machine_selected and p_waypoint and p_waypoint.get_selected_object() != _machine_selected

func _on_waypoint_hud_waypoint_selected(p_object):
	if p_object is MachineCharacter and not _machine_selected:
		_machine_selected = p_object
		_update_action_panel()
		_info_object = p_object

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
	MultiplayerServer.arrives_on_planet(0, _solar_system.get_reference_stellar_body_id(), _username)
	
	

func _on_planet_status_requested(solar_system_id, planet_id, data):
#	await get_tree().create_timer(1.5).timeout
	var machines  = data.machines
	var planet: StellarBody = _solar_system.get_reference_stellar_body_by_id(planet_id)
	for md in machines:
		_on_add_machine(md.owner_id, planet_id, md.asset_id, md.id, md)
		var m: MachineCharacter = _machines[int(md.id)]
		m.set_task_batch(md.tasks)
		
		var final_position = Util.unit_coordinates_to_unit_vector(Vector2(md.location.x, md.location.y)) * planet.radius
		var location_id: int = Server.get_mine_deposit_id_by_unit_coordinates(solar_system_id, planet_id, Vector2(md.location.x, md.location.y))
#		print("Location id: ", location_id)
		m.set_planet_mine_location(location_id)
		m.global_position = final_position
	
	
	load_waypoints()

func _on_add_machine(player_id: String, _planet_id: int, machine_asset_id: int, machine_instance_id: int, p_data) -> void:
	var asset: Node3D = _asset_inventory.generate_asset(machine_asset_id)
	_machines[machine_instance_id]  = asset
	var planet: StellarBody = _solar_system.get_reference_stellar_body()
	var spawn_point := planet.get_spawn_point()
	var miner: Miner = asset as Miner
	if miner:
		miner.set_id(machine_instance_id)
		planet.add_machine(miner)
		miner.set_planet(planet)
		miner.set_owner_id(player_id)
		miner.global_position = spawn_point
		miner.configure_waypoint(_solar_system.is_planet_mode_enabled())
		miner.mineral_extracted.connect(_on_mineral_extracted)
	var md: Dictionary = p_data.machine_data if p_data.has("machine_data") else p_data
	miner.set_machine_data(md)


func _on_task_cancelled(solar_system_id: int, planet_id: int, machine_id: int, task_id: int, requester_id: String) -> void:
	var w: IWorker = _machines.get(machine_id, null)
	if w:
		w.cancel_task(task_id)

func _on_task_requested(solar_system_id: int, planet_id: int, machine_id: int, requester_id: String, p_task_data: Dictionary) -> void:
	if not _machines.has(machine_id):
		return
	
	var worker: IWorker = _machines[machine_id]
	if worker.do_task(p_task_data.task_name, p_task_data) != OK:
		push_error("Cannot execute task {}".format(p_task_data.task_id))


func load_waypoints():
	var deposits = Server.planet_get_deposits(_solar_system.get_reference_stellar_body_id())
	for index in deposits.size():
		var mine = deposits[index]
#		var waypoint: Waypoint = WaypointScene.instantiate()
		var planet: StellarBody = _solar_system.get_reference_stellar_body()
		planet.add_mine_at_coordinates(mine.pos)
#		waypoint.location = mine.pos
#		waypoint.info = "Mine pos: {}\nAmount: {}".format([mine.pos, mine.amount], "{}")
#		waypoint.location_id = index
#		planet.node.add_child(waypoint)
#		planet.waypoints.append(waypoint)
#		waypoint.global_position = Util.coordinate_to_unit_vector(mine.pos) * planet.radius


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and not event.is_echo():
			if event.keycode == KEY_ESCAPE:
				if _settings_ui.visible:
					_settings_ui.hide()
				elif _pause_menu.visible:
					_pause_menu.hide()
					_mouse_capture.capture()
				else:
					_pause_menu.show()

##############################
# Helper functions
##############################
func spawn_machine(machine_id: int) -> void:
	if _machines.has(machine_id):
		print("This amchine already exists in the game")
		return
	Server.miner_spawn(0, _solar_system.get_reference_stellar_body_id(), _username, machine_id)
	
func machine_move(machine_id: int, from, to) -> void:
	if not _machines.has(machine_id):
		return
	var machine: MachineCharacter = _machines[machine_id]
	machine.set_planet_mine_location(-1)
	var data := MoveMachineData.new()
	data.machine_speed = machine.get_max_speed()
	data.from = Util.position_to_unit_coordinates(from)
	data.to = Util.position_to_unit_coordinates(to)
	data.planet_radius = _solar_system.get_reference_stellar_body().radius
	Server.machine_move(0, _solar_system.get_reference_stellar_body_id(), machine_id, _username, "move", data)
	_machine_selected = null
	
func machine_move_at_location_id(machine_id: int, location_id: int) -> void:
	if not _machines.has(machine_id):
		return
	var machine: MachineCharacter = _machines[machine_id]
	machine.set_planet_mine_location(location_id)
	var data := MoveMachineData.new()
	data.machine_speed = machine.get_max_speed()
	data.from = Util.position_to_unit_coordinates(machine.position)
	var to: Vector2 = Server.planet_get_deposits(_solar_system.get_reference_stellar_body_id())[location_id].pos
	data.to = Util.coordinate_to_unit_coordinates(to)
	data.planet_radius = _solar_system.get_reference_stellar_body().radius
	Server.machine_move(0, _solar_system.get_reference_stellar_body_id(), machine_id, _username, "move", data)
	_machine_selected = null

# TODO remove position. This should be gathered from server.
func machine_mine(p_machine_id: int) -> void:
	if not _machines.has(p_machine_id):
		return
	var machine: MachineCharacter = _machines[p_machine_id]
	
	if machine.get_current_task() != null:
		print("Cannot mine while doing another task")
		return
	var data := Miner.MineTaskData.new()
	data.planet_id = _solar_system.get_reference_stellar_body_id()
	var location_id: int = machine.get_planet_mine_location_id()
	if location_id == -1:
		print("the machine is not located on any mine location")
		return
	data.location_id = location_id
	data.machine_id = machine.get_id()
	Server.machine_mine(0, get_solar_system().get_reference_stellar_body_id(), machine.get_id(), _username, "mine", data)
	_machine_selected = null

func cancel_task(machine_id: int, task_id: int) -> void:
	Server.cancel_task(0, get_solar_system().get_reference_stellar_body_id(), machine_id, task_id, _username)

func finish_task(machine_id: int, task_id: int) -> void:
	Server.finish_task(0, get_solar_system().get_reference_stellar_body_id(), machine_id, task_id, _username)


#func get_planet_status() -> void:
#	Server.get_planet_status(0, _solar_system.get_reference_stellar_body_id(), _username)

func despawn_machine(p_machine_id: int) -> void:
	Server.despawn_machine(0, _solar_system.get_reference_stellar_body_id(), p_machine_id, _username)

func buy_ship() -> void:
	
	pass


func enter_ship():
	var camera: Camera3D = get_viewport().get_camera_3d()
	var c: Node = _local_player.get_character()
	c.queue_free()
	_local_player.set_physics_process(false)
	_local_player.unpossess()
	_local_player.queue_free()
	var ship: Ship = get_tree().get_nodes_in_group("ship")[0]
	_solar_system.target_ship = ship
	_local_player = ShipController.instantiate() as AController
	_local_player.possess(ship)
	add_child(_local_player)
	ship.enable_controller()
	camera.set_target(ship)


func exit_ship():
	var camera: Camera3D = get_viewport().get_camera_3d()
	var ship: Ship = _local_player.get_character()
	ship.disable_controller()
#	c.queue_free()
	_local_player.set_physics_process(false)
	_local_player.unpossess()
	_local_player.queue_free()
	var char: Character = CharacterScene.instantiate()
	_solar_system.add_child(char)
	char.global_position = ship.get_character_spawn_position()
	_solar_system.target_ship = null
	_local_player = LocalControllerScene.instantiate() as AController
	_local_player.possess(char)
	add_child(_local_player)
	camera.set_target(char)

##############################
# End Helper functions
##############################


func _on_solar_system_loading_progressed(info):
	if info.finished:
		Server.get_machine_assets(_username)

func get_user_id() -> String:
	return _username


func prepare_task(p_task_node: ITask, p_machine_id: int):
	_task_ui_from_node_selected = p_task_node
	_machine_selected = _machines[p_machine_id]

func _on_despawn_machine_requested(p_solar_system_id: int, p_planet_id: int, p_machine_id: int):
	var m: MachineCharacter = _machines[p_machine_id]
	if m == _info_object:
		_info_object = null
	
	_machines.erase(p_machine_id)
	m.destroy_machine()

func _on_floating_resources_updated(p_solar_system_id, p_planet_id, p_resources):
	_load_floating_resource(p_solar_system_id, p_planet_id, p_resources)

func _load_floating_resource(p_solar_system_id, p_planet_id, p_resources):
	var floating_resources = p_resources
	for fr in floating_resources:
		var instance = PlanetMaterialManager.spawn_material(fr.type, fr.uuid)
		var sb: StellarBody = _solar_system.get_reference_stellar_body()
		sb.node.add_child(instance)
		var coord = fr.unit_coordinates
		var dir = Util.unit_coordinates_to_unit_vector(Vector2(coord.x, coord.y))
		
		var found: bool = false
		
		while not found:
			await get_tree().process_frame
			var query := PhysicsRayQueryParameters3D.new()
			query.from = sb.radius * 10 * dir
			query.to = Vector3.ZERO
			var state := get_world_3d().direct_space_state
			var result := state.intersect_ray(query)
			
			if not result.is_empty():
				instance.position = result.position
				found = true
	print("Spawned all resources")

func get_machine(p_machine_id: int) -> MachineCharacter:
	return _machines.get(p_machine_id, null)


func _on_pause_menu_exit_to_menu_requested():
	pass # Replace with function body.

func _on_PauseMenu_exit_to_menu_requested():
	_save_world()
	exit_to_menu_requested.emit()


func _on_PauseMenu_exit_to_os_requested():
	_save_world()
	get_tree().quit()


func _on_PauseMenu_resume_requested():
#	_pause_menu.hide()
#	_mouse_capture.capture()
	pass


func _on_PauseMenu_settings_requested():
	_settings_ui.show()
	# The settings UI exists before the game is instanced so it might be behind.
	# This makes sure it shows in front.
	_settings_ui.move_to_front()

func _save_world():
	print("Saving world")
	_solar_system.save_system()
	
func set_settings_ui(p_settings_ui):
	_settings_ui = p_settings_ui

func remove_player(p_player_id: int):
	var c: Character = _players.get(p_player_id)
	if c:
		c.queue_free()
		_players.erase(p_player_id)


func on_resource_colleted(p_machine_id, p_amount_type, p_amount) -> void:
	print("resource collected")
	pass
