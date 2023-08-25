extends Game

@export var _pickable_object_scene: PackedScene


func _ready():
	super._ready()
#	_player_station_ui.visible = true

func _spawn_player() -> Character:
	var a = await super._spawn_player()
	# find a mine point
	var points := []
	while points.size() == 0:
		await get_tree().process_frame
		points = Server.planet_get_deposits(2)
	
	var query := PhysicsRayQueryParameters3D.new()
	query.from = Util.coordinate_to_unit_vector(points[0].pos) * _solar_system.get_reference_stellar_body().radius * 10
	query.to = Vector3.ZERO
	var state := get_world_3d().direct_space_state
	var result := {}
	while result.is_empty():
		await get_tree().process_frame
		result = state.intersect_ray(query)
	
	var station: Station = get_tree().get_nodes_in_group("portal_station")[0]
	a.position = station.character_spawn_position
	return a

func _on_planet_status_requested(solar_system_id, planet_id, data):
	super._on_planet_status_requested(solar_system_id, planet_id, data)
	
	var station = StationScene.instantiate()
	var body: StellarBody = _solar_system.get_reference_stellar_body()
	body.node.add_child(station)
	var result := {}
	var query := PhysicsRayQueryParameters3D.new()
	query.from = body.radius * 10.0 * Vector3.UP
	query.to = Vector3.ZERO
	var state := get_world_3d().direct_space_state
	
	while result.is_empty():
		await get_tree().process_frame
		result = state.intersect_ray(query)
	station.position = result.position


func _on_loading_progressed(p_progress_info):
	await super._on_loading_progressed(p_progress_info)
	if p_progress_info.finished:
		var points := []
		while points.size() == 0:
			await get_tree().process_frame
			points = Server.planet_get_deposits(2)
		
		var query := PhysicsRayQueryParameters3D.new()
		query.from = Util.coordinate_to_unit_vector(points[0].pos) * _solar_system.get_reference_stellar_body().radius * 10
		query.to = Vector3.ZERO
		var state := get_world_3d().direct_space_state
		var result := {}
		while result.is_empty():
			await get_tree().process_frame
			result = state.intersect_ray(query)
		
		await get_tree().create_timer(1.0).timeout
		#MultiplayerServer.join()
		



func buy_ship() -> void:
	if get_tree().get_nodes_in_group("ship").size() > 0:
		print("You already has a ship!")
		return
	super.buy_ship()
	var station: Station = get_tree().get_first_node_in_group(&"portal_station")
	if station == null:
		push_error("Station is null")
		return
	var ship: Ship = ShipScene.instantiate()
	_solar_system.add_child(ship)
	ship.position = station.spaceship_spawn_position


func enter_ship():
	super.enter_ship()
#	_player_station_ui.visible = false

func exit_ship():
	super.exit_ship()
#	_player_station_ui.visible = true

func pm_enabled(value: bool):
	super.pm_enabled(value)
#	_player_station_ui.visible = not value

func show_interactive_menu(p_objects: Array):
	super.show_interactive_menu(p_objects)
	_hud.config_menu(p_objects)
