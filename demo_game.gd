extends Game

@export var _pickable_object_scene: PackedScene

func _ready():
	super._ready()

func _spawn_player() -> Character:
	var a = await super._spawn_player()
	# find a mine point
	var points := []
	while points.size() == 0:
		await get_tree().process_frame
		points = Server.planet_get_deposits(2)
	
#	Server.get_planet_list(0)
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
#	a.position = result.position + result.position.normalized() * 2.0
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
			
#		var ship: Ship = ShipScene.instantiate()
#		_solar_system.add_child(ship)
#		var pos: Vector3 = result.position
#		pos = pos.rotated(Vector3.UP, (PI * 0.1) * 0.1)
#		ship.position = pos
		
#		ship.look_at(_local_player.get_character().global_position)
		
		await get_tree().create_timer(1.0).timeout
		MultiplayerServer.join()


func buy_ship() -> void:
	super.buy_ship()
	var station: Station = get_tree().get_nodes_in_group("portal_station")[0]
	var ship: Ship = ShipScene.instantiate()
	_solar_system.add_child(ship)
	ship.position = station.spaceship_spawn_position
