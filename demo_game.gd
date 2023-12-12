extends Game

#const StellarBody = preload("res://solar_system/stellar_body.gd")

#@export var _pickable_object_scene: PackedScene



func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	MultiplayerServer.packet_recived.connect(_on_multiplayer_event)
	super._ready()



func _on_multiplayer_event(multiplayer_event: MultiplayerServerAPI.MessageType, data: Dictionary) -> void:
	print("Multiplayer Event: " + str(multiplayer_event))
	match multiplayer_event:
		MultiplayerServerAPI.MessageType.SPAWN_SHIP:
			var ship_data: MultiplayerServerAPI.ShipData = MultiplayerServerAPI.ShipData.new(data["id"], data["owner"], true, data["ownerId"])
			ship_data.position = Util.deserialize_vec3(data["position"])
			spawn_ship(ship_data)
		MultiplayerServerAPI.MessageType.SHIP_INTERACT_RESULT:
			var result: int = data["status"]
			
			if result == 0:
				print("Enter ship")
				_enter_ship(data["shipId"])
			elif result == 3:
				var spawnPos: Vector3 = Util.deserialize_vec3(data["newPos"])
				_exit_ship(spawnPos)
			else:
				OS.alert("Ship already controlled")
		MultiplayerServerAPI.MessageType.DESPAWN_PLAYER:
			despawn_player(data["desId"])
		MultiplayerServerAPI.MessageType.SPAWN_PLAYER:
			var pData: MultiplayerServerAPI.PlayerData = MultiplayerServer.get_player_data_by_id(data["spawnId"])
			pData.position = Util.deserialize_vec3(data["newPos"])
			var c: Character = await spawn_player(pData, true)
			c.global_position = pData.position


func _on_peer_connected(peer: int) -> void:
	if _solar_system.has_node("player_" + str(peer)):
		return
	
	spawn_player(MultiplayerServer.get_player_data_by_peer(peer))

func _on_peer_disconnected(peer: int) -> void:
	despawn_player(MultiplayerServer.find_id_by_peer(peer))

func _spawn_player(dir: Vector3 = Vector3.ZERO) -> Character:
	var a = await super._spawn_player(dir)
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

func _on_loading_progressed(p_progress_info) -> void:
	await super._on_loading_progressed(p_progress_info)
	"""if p_progress_info.finished:
		var points: Array = []
		while points.size() == 0:
			await get_tree().process_frame
			points = Server.planet_get_deposits(2)
		
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
		query.from = Util.coordinate_to_unit_vector(points[0].pos) * _solar_system.get_reference_stellar_body().radius * 10
		query.to = Vector3.ZERO
		var state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
		var result: Dictionary = {}
		while result.is_empty():
			await get_tree().process_frame
			result = state.intersect_ray(query)
		
		await get_tree().create_timer(1.0).timeout"""



func buy_ship(spawn_position: Vector3) -> void:
	super.buy_ship(spawn_position)


func enter_ship(ship_id: String) -> void:
	super.enter_ship(ship_id)
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
