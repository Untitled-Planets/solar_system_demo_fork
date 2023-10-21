extends Game

#const StellarBody = preload("res://solar_system/stellar_body.gd")

#@export var _pickable_object_scene: PackedScene



func _ready():
	if MultiplayerServer.has_signal(&"update_client_network_frame") and MultiplayerServer.has_signal(&"on_update_client_buffer_data"):
		#MultiplayerServer.update_client_network_frame.connect(_update_client_multiplayer)
		#MultiplayerServer.on_update_client_buffer_data.connect(_on_update_buffer_data)
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		MultiplayerServer.multiplayer_event.connect(_on_multiplayer_event)
	
	super._ready()
#	_player_station_ui.visible = true


func request_sync() -> void:
	pass




func _on_multiplayer_event(multiplayer_event: MultiplayerServer.NetworkNotification, from_peer: int, data: Dictionary = {}) -> void:
	match  multiplayer_event:
		MultiplayerServer.NetworkNotification.SHIP_SPAWN:
			var ship_id: int = data.ship_id
			_ships[ship_id] = {
				"owner": from_peer,
				"instanced": true
			}
			
			var station: Station = get_tree().get_first_node_in_group(&"portal_station")
			var ship: Ship = ShipScene.instantiate()
			ship.set_multiplayer_authority(from_peer)
			ship.name = &"ship_%s" % ship_id
			_solar_system.add_child(ship)
			ship.position = station.spaceship_spawn_position
		MultiplayerServer.NetworkNotification.PLAYER_SPAWN:
			if not _solar_system.has_node("player_%s" % from_peer):
				var c: Character = await _spawn_player()
				c.set_multiplayer_authority(from_peer)
				var r: RemoteController = RemoteControllerScene.instantiate()
				c.set_controller(r)
				r.possess(c)
				add_child(r)
				c.name = &"player_%s" % from_peer
				_solar_system.add_child(c)
				r.set_uuid(str(from_peer))
				if data.has("pos"):
					c.global_position = data.get("pos")
		MultiplayerServer.NetworkNotification.PLAYER_DESPAWN:
			if _solar_system.has_node("player_%s" % from_peer):
				var character: Character = _solar_system.get_node("player_%s" % from_peer) as Character
				if character.get_controller() != null:
					character.get_controller().unpossess()
					character.get_controller().queue_free()
				character.queue_free()
		_:
			pass

func _on_peer_connected(peer: int) -> void:
	if _solar_system.has_node("player_" + str(peer)):
		return
	
	var new_character: Character = await _spawn_player()
	new_character.set_multiplayer_authority(peer)
	new_character.set_meta(&"entity_id", MultiplayerServer.find_id_by_peer(peer))
	new_character.set_meta(&"entity_type", "PLAYER")
	new_character.set_meta(&"origin_peer", peer)
	var r: RemoteController = RemoteControllerScene.instantiate()
	new_character.set_controller(r)
	r.possess(new_character)
	add_child(r)
	new_character.name = "player_" + str(peer)
	_solar_system.add_child(new_character)
	r.set_uuid(str(peer))


func _on_peer_disconnected(peer: int) -> void:
	if not _solar_system.has_node("player_" + str(peer)):
		return
	
	var character: Character = _solar_system.get_node_or_null("player_" + str(peer))
	
	if character:
		var r: RemoteController = character.get_controller()
		character.queue_free()
		r.queue_free()

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
	
	var station: Station = get_tree().get_first_node_in_group("portal_station")
	if station:
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



func buy_ship(spawn_position: Vector3) -> void:
	if get_tree().get_nodes_in_group(&"ship").size() > 0:
		print("You already has a ship!")
		return
	super.buy_ship(spawn_position)
	var station: Station = get_tree().get_first_node_in_group(&"portal_station")
	if station == null:
		push_error("Station is null")
		return
	var ship: Ship = ShipScene.instantiate()
	ship.add_to_group(&"ship")
	var id: int = MultiplayerServer.get_unique_id()
	ship.set_multiplayer_authority(id)
	randomize()
	var ship_id: int = id + (randi() % 1 << 16)
	ship.name = &"ship_%s" % ship_id
	_solar_system.add_child(ship)
	print("spawn position: %s" % spawn_position)
	ship.global_position = spawn_position
	var data: Dictionary = {
		"owner": id,
		"instanced": true,
		"ship_id": ship_id,
		"position": spawn_position
	}
	
	_ships[ship_id] = {
		"instanced": true,
		"owner": id
	}
	#MultiplayerServer.send_network_notification(MultiplayerServer.NetworkNotification.SHIP_SPAWN, data)


func enter_ship() -> void:
	super.enter_ship()
#	_player_station_ui.visible = false

func exit_ship() -> void:
	super.exit_ship()
#	_player_station_ui.visible = true

func pm_enabled(value: bool):
	super.pm_enabled(value)
#	_player_station_ui.visible = not value

func show_interactive_menu(p_objects: Array):
	super.show_interactive_menu(p_objects)
	_hud.config_menu(p_objects)
