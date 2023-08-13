extends Node

class CustomMultiplayerAPI extends SceneMultiplayer:
	pass
	
	func _auth_callback() -> void:
		pass


class ObjectData extends RefCounted:
	var id: int
	
	func _init(id: int) -> void:
		self.id = id

class PlanetData extends ObjectData:
	var resources: Dictionary = {}
	
	func _init(id: int = -1, resources: Dictionary = {}) -> void:
		super._init(id)
		self.resources = resources

class SolarSystemData extends ObjectData:
	var playents: Array[PlanetData]
	
	func _init(id: int = -1, planets: Array[PlanetData] = []) -> void:
		super._init(id)
		self.planets = planets

class ResourceCollectionData extends RefCounted:
	var resource_id: String
	var progress: float
	var user_id: String


signal resource_collection_progressed(resource_id, p_procent)
signal resource_collection_finished(resource_id)
signal resource_collection_started(resource_id)
signal users_updated(user_joining, user_leaving)
signal user_position_updated(p_user_id, player_position)
signal resources_generated(solar_system_id, planet_id ,resources)
signal planet_status_requested(solar_system_id, planet_id, data)
signal floating_resources_updated(solar_system_id, planet_id, resources)
signal data_updated(data: Dictionary)

signal on_update_client_buffer_data(buffer: SyncBufferData)
signal update_client_network_frame(delta: float)
signal request_instance_network_object(origin_peer: int, network_object_data: NetworkObjectData, sync_data: Dictionary)

const DEFAULT_PORT: int = 4422
const MULTIPLAYER_FPS: int = 20

enum UpdateMode {
	IDLE = 0,
	PHYSICS = 1
}

var _sync_delta: float = 1.0 / MULTIPLAYER_FPS
var _delta_acc: float = 0.0
var _resources: Dictionary = {}
var _solar_systems: Array[SolarSystemData] = []
var _planet_system: Dictionary = {}
var _resource_selected: ResourceCollectionData = null
var _peer: ENetMultiplayerPeer = null
var network_objects: Dictionary = {}
var waiting_network_objects_pairing: Array[NetworkObjectData] = []

var update_mode: UpdateMode = UpdateMode.IDLE





func setup_client(address: String, port: int = DEFAULT_PORT) -> Error:
	close()
	
	_peer = null
	_peer = ENetMultiplayerPeer.new()
	
	var err: Error = _peer.create_client(address, port)
	
	if err != OK:
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	if not multiplayer.connected_to_server.is_connected(_on_server_connected):
		multiplayer.connected_to_server.connect(_on_server_connected)
	
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	if not multiplayer.connection_failed.is_connected(_on_connection_fail):
		multiplayer.connection_failed.connect(_on_connection_fail)
	
	return OK


func setup_server(port: int = DEFAULT_PORT) -> Error:
	close()
	
	_peer = null
	_peer = ENetMultiplayerPeer.new()
	
	var err: Error = _peer.create_server(port)
	
	if err != OK:
		return err
	
	multiplayer.multiplayer_peer = _peer
	
	if  not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	
	if  not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_connected)
	
	join()
	return OK


func close() -> void:
	if not multiplayer.has_multiplayer_peer():
		return
	
	if multiplayer.multiplayer_peer == null:
		return
	
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		waiting_network_objects_pairing.clear()
		network_objects.clear()
		multiplayer.multiplayer_peer.close()


func get_network_object(network_id: int) -> NetworkObjectData:
	return network_objects.get(network_id, null)


func register_network_object(n: NetworkEntity) -> void:
	assert(n != null, "")
	
	if connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		waiting_network_objects_pairing.append(null)
	
	var data: NetworkObjectData = NetworkObjectData.new(n)
	var n_name: StringName = n.get_name()
	var origin: NetworkEntity.OriginControl = n.origin_control
	
	if multiplayer.is_server():
		randomize()
		var network_id: int = randi()
		n._peer_id = network_id
		
		if origin != NetworkEntity.OriginControl.SERVER:
			pass
			
		
		network_objects[network_id] = data
	else:
		waiting_network_objects_pairing.append(data)
		remote_register_network_object.rpc_id(1, data.get_instance_id(), n_name, origin)



@rpc("any_peer")
func remote_register_network_object(object_id: int, node_name: StringName, origin_control: NetworkEntity.OriginControl) -> void:
	assert(not multiplayer.is_server())
	if not multiplayer.is_server():
		return
	
	var sender: int = multiplayer.get_remote_sender_id()
	
	# find in current register network nodes
	var target_object: NetworkObjectData = null
	
	for k in network_objects.keys():
		var object_data: NetworkObjectData = network_objects[k]
		if object_data.is_name(node_name):
			target_object = object_data
			break
	
	var node_network_id: int = target_object.get_network_id()
	
	remote_confirm_register_network_object.rpc_id(sender, object_id, node_network_id)



func replicate_object_network(origin_peer: int, network_id: int, config: Dictionary) -> void:
	pass


@rpc("authority")
func remote_confirm_register_network_object(object_id: int, network_id: int) -> void:
	var object_origin: NetworkObjectData = null
	var del_idx: int = -1
	
	for i in range(waiting_network_objects_pairing.size()):
		var object: NetworkObjectData = waiting_network_objects_pairing[i]
		var id: int = object.get_instance_id()
		
		if object_id == id:
			object_origin = object
			break
	
	
	assert(object_origin != null or del_idx > -1, "")
	
	waiting_network_objects_pairing.remove_at(del_idx)
	
	object_origin.set_network_id(network_id)
	network_objects[network_id] = object_origin



func get_timestamp() -> int:
	return Time.get_ticks_msec()


func get_local_time() -> int:
	return roundi(Time.get_unix_time_from_system())


func _on_peer_connected(peer: int) -> void:
	print("New peer %s connected" % peer)


func _on_peer_disconnected(peer: int) -> void:
	print("Peer %s disconnected" % peer)



func _on_server_connected() -> void:
	print("Connected to server")


func _on_connection_fail() -> void:
	printt("Connection failed")


func _on_server_disconnected() -> void:
	print("Disconnected from server")



func connection_status() -> MultiplayerPeer.ConnectionStatus:
	if multiplayer.has_multiplayer_peer():
		return MultiplayerPeer.CONNECTION_DISCONNECTED
	return multiplayer.multiplayer_peer.get_connection_status()


func init() -> void:
	Server.resource_collected.connect(_on_resource_collected)
	Server.planet_listed.connect(_on_planet_listed)
	Server.get_planet_list(0)
	Server.planet_status_requested.connect(_on_planet_status_requested)


func _on_planet_status_requested(p_solar_system_id, p_planet_id, data):
	planet_status_requested.emit(p_solar_system_id, p_planet_id, data)
#	_generate_floating_resources_for_solar_system(p_solar_system_id, [int(p_planet_id)])
	_resources[int(p_solar_system_id)] = {int(p_planet_id): _generate_resources(100)} # temp
	floating_resources_updated.emit(p_solar_system_id, p_planet_id, _resources[int(p_solar_system_id)][int(p_planet_id)])


func get_planet_status(p_solar_system_id, p_planet_id, p_requester) -> void:
	Server.get_planet_status(p_solar_system_id, p_planet_id, p_requester)

func _on_planet_listed(p_solar_system_id, p_planet_ids) -> void:
	_generate_floating_resources_for_solar_system(p_solar_system_id, p_planet_ids)
	pass

func _generate_floating_resources_for_solar_system(p_solar_system_id, p_planet_ids) -> void:
	if _resources.has(p_solar_system_id):
		# clean
		pass
	else:
		_resources[p_solar_system_id] = _generate_resources_for_planets(p_planet_ids)

func _generate_resources_for_planets(p_planet_ids) -> Dictionary:
	var resources: Dictionary = {}
	for planet_id in p_planet_ids:
		resources[int(planet_id)] = _generate_resources(100)
	return resources


func get_resource_for_planet(p_solar_system_id, p_planet_id, p_resource) -> Array:
	return _resources[p_solar_system_id][p_planet_id]

func _generate_resources(p_amount: int) -> Array[Dictionary]:
	var rs: Array[Dictionary] = []
	for index in p_amount:
		# use dictionary for now
		rs.append({
			uuid = "",
			type = 0,
			unit_coordinates = {
				x = randf_range(-1, 1),
				y = randf_range(0, 1)
			}
		})
	
	return rs


func join() -> String:
	var id: String = "dummy-id"
	users_updated.emit([id], [])
	return id


func _initialize()  -> void:
	var ssd: SolarSystemData = SolarSystemData.new()
	_solar_systems.append(ssd)


func _on_resource_collected(resource_id: String, resource_amount: int)  -> void:
	resource_collection_finished.emit(resource_id)

func _generate_resources_for_planet(p_planet_id) -> PlanetData:
	return null

var _debug_player_pos: Vector3

func send_last_position(p_user_id: String, p_position: Vector3)  -> void:
	_debug_player_pos = p_position

func start_resource_collect(p_solar_system_id: int, p_planet_id: int, p_resource_id: String, p_player_id: String) -> void:
	_resource_selected = ResourceCollectionData.new()
	_resource_selected.progress = 0
	_resource_selected.resource_id = p_resource_id
	_resource_selected.user_id = p_player_id
	resource_collection_started.emit(p_resource_id)


func arrives_on_planet(p_solar_system_id: int, p_planet_id: int, p_player_id):
	MultiplayerServer.get_planet_status(p_solar_system_id, p_planet_id, p_player_id)
	print("Arrving planet {0}".format([p_planet_id]))

# This should be called from server
func finish_resource_collect(p_resource_id: int):
	pass


func _process(delta: float) -> void:
	if update_mode == UpdateMode.IDLE:
		_update(delta)



func _physics_process(delta: float) -> void:
	if update_mode == UpdateMode.PHYSICS:
		_update(delta)


func pack_data() -> Dictionary:
	var data: Dictionary = {
		"timestamp": get_timestamp(),
		"entities": pack_data_from_group(&"network")
	}
	return data


func pack_data_from_group(p_group: String) -> Dictionary:
	var ns: Array = get_tree().get_nodes_in_group(p_group)
	var data: Dictionary = {}
	var is_server: bool = multiplayer.is_server()
	var peer_id: int = multiplayer.get_unique_id()
	
	for n in ns:
		if n is NetworkEntity:
			if n.has_method(&"serialize"):
				# It will only make sure to pack the data if the source control is
				# equal to the instance where this function is called.
				if peer_id == n._network_control:
					var serialize_data: Dictionary = n.serialize()
					if not serialize_data.is_empty():
						data[n._peer_id] = serialize_data
	
	return data


func _update(delta: float) -> void:
	if _resource_selected:
		_resource_selected.progress = _resource_selected.progress + delta
		resource_collection_progressed.emit(_resource_selected.resource_id, _resource_selected.progress)
		if _resource_selected.progress >= 1.0:
			Server.collect_item(_resource_selected.user_id, _resource_selected.resource_id, 1, 10)
			_resource_selected = null
	
	_delta_acc += delta
	
	if _delta_acc > _sync_delta:
		if multiplayer.is_server():
			_update_server_multiplayer(delta)
		else:
			update_client_network_frame.emit(delta)
		user_position_updated.emit("dummy-id", _debug_player_pos)
		_delta_acc = 0.0
		
		var data := pack_data()
		data_updated.emit(data)


func _update_server_multiplayer(delta: float) -> void:
	var buffer: Dictionary = pack_data()
	_on_server_data_recived.rpc(buffer)


@rpc("authority", "unreliable")
func _on_server_data_recived(buffer: Dictionary) -> void:
	if not buffer.has("timestamp") or not buffer.has("entities"):
		return
	
	var buffer_data: SyncBufferData = SyncBufferData.new(buffer["timestamp"], buffer["entities"])
	on_update_client_buffer_data.emit(buffer)

