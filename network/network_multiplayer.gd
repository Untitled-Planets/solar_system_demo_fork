extends Node

class CustomMultiplayerAPI extends SceneMultiplayer:
	pass
	
	func _auth_callback() -> void:
		pass


class ObjectData extends RefCounted:
	var id: int
	
	@warning_ignore("shadowed_variable")
	func _init(id: int) -> void:
		self.id = id

class PlanetData extends ObjectData:
	var resources: Dictionary = {}
	
	@warning_ignore("shadowed_variable")
	func _init(id: int = -1, resources: Dictionary = {}) -> void:
		super._init(id)
		self.resources = resources

class SolarSystemData extends ObjectData:
	var playents: Array[PlanetData]
	
	@warning_ignore("shadowed_variable")
	func _init(id: int = -1, planets: Array[PlanetData] = []) -> void:
		super._init(id)
		self.planets = planets

class ResourceCollectionData extends RefCounted:
	enum CollectionType {
		MINERAL,
		REFINED
	}
	
	var resource_id: String
	var progress: float
	var user_id: String
	var type: CollectionType
	var amount: int = 10
	
	func _init(resource_id: String, progress: float, user_id: String, type: CollectionType) -> void:
		self.resource_id = resource_id
		self.progress = progress
		self.user_id = user_id
		self.type = type


signal resource_collection_progressed(resource_id: String, p_procent: float)
signal resource_collection_finished(resource_id: String, amount: int)
signal resource_collection_started(resource_id: String)

signal resource_refined_progress(p_resource_id: String, p_procent: float)
signal resource_refined_finished(p_resource_id: String, amount: int)
signal resource_refined_started(p_resource_id: String)

signal refined_resource_finished(resource_is: String, amount: int)

signal users_updated(user_joining, user_leaving)
signal user_position_updated(p_user_id, player_position)
signal resources_generated(solar_system_id, planet_id ,resources)
signal planet_status_requested(solar_system_id, planet_id, data)
signal floating_resources_updated(resources)

signal data_updated(data: Dictionary)

signal server_started
signal client_started
signal on_update_client_buffer_data(buffer: SyncBufferData)
signal on_update_server_buffer_data(buffer: SyncBufferData)
signal update_client_network_frame(delta: float)
signal request_instance_network_object(origin_peer: int, network_object_data: NetworkObjectData, sync_data: Dictionary)
signal network_entity_propety_changed(entity: NetworkEntity, property: StringName, value: Variant)
signal multiplayer_event(event: NetworkNotification, origin_peer: int, data: Dictionary)

signal inventory_updated(inventory: Array)

const DEFAULT_PORT: int = 3000
const MULTIPLAYER_FPS: int = 10
const SERVER_PEER: int = 1

enum UpdateMode {
	IDLE = 0,
	PHYSICS = 1
}

enum NetworkNotification {
	PLAYER_SPAWN,
	PLAYER_DESPAWN,
	SHIP_SPAWN,
	SHIP_DESPAWN,
	ENTER_SHIP, # To-Do: i need to use this 
	EXIT_SHIP
}

var _sync_delta: float = 1.0 / MULTIPLAYER_FPS
var _delta_acc: float = 0.0
var _resources: Dictionary = {}
var _solar_systems: Array[SolarSystemData] = []

var _planet_system: Dictionary = {}
var _resource_selected: ResourceCollectionData = null
var _resource_selected_refined: ResourceCollectionData = null
var network_objects: Dictionary = {}
var waiting_network_objects_pairing: Array[NetworkObjectData] = []

var update_mode: UpdateMode = UpdateMode.IDLE
var _debug_player_pos: Vector3

var _mineral_amount: int = 0
var refined_resource: int = 0

var _ws: MultiplayerServerWebSocket = MultiplayerServerWebSocket.new()

func _ready() -> void:
	add_child(_ws)
	_ws.packet_recived.connect(_on_packet_recived)


func _on_packet_recived(type: MultiplayerServerWebSocket.MessageType, data: Dictionary) -> void:
	match type:
		MultiplayerServerWebSocket.MessageType.DESPAWN_RESOURCE:
			var mineral_id: String = data["resourceId"]
			_ws.reference_body.remove_mineral_from_id(mineral_id)
		MultiplayerServerWebSocket.MessageType.UPDATE_STATE:
			var id: String = data["id"]
			if network_objects.has(id):
				var properties: Dictionary = Util.deserialize_dic(data["state"])
				var entity: NetworkEntity = network_objects[id]
				entity._on_data_recived(properties)
			else:
				push_error("The id: %s not exist" % id)
		MultiplayerServerWebSocket.MessageType.COLLECT_RESOURCE_FINISHED:
			var inventoryArr: Array = data.get("inventory", [])
			var inventory: MultiplayerServerAPI.Inventory = MultiplayerServerAPI.Inventory.new()
			
			for i in inventoryArr:
				var item: MultiplayerServerAPI.Item = MultiplayerServerAPI.Item.new(i["id"], i["name"], i["type"], i["stock"], i.get("description", ""))
				inventory.push(item)
			
			_ws._update_inventory(inventory)
			
			resource_collection_finished.emit(_ws.current_player, 0)
			inventory_updated.emit(inventory.items)
		MultiplayerServerWebSocket.MessageType.REFIN_RESOURCE_FINISHED:
			var inventoryArr: Array = data.get("inventory", [])
			var inventory: MultiplayerServerAPI.Inventory = MultiplayerServerAPI.Inventory.new()
			
			for i in inventoryArr:
				var item: MultiplayerServerAPI.Item = MultiplayerServerAPI.Item.new(i["id"], i["name"], i["type"], i["stock"], i.get("description", ""))
				inventory.push(item)
			
			_ws._update_inventory(inventory)
			
			refined_resource_finished.emit(_ws.current_player, 0)
			inventory_updated.emit(inventory.items)
		MultiplayerServerWebSocket.MessageType.ENTER_SHIP:
			pass
		MultiplayerServerWebSocket.MessageType.EXIT_SHIP:
			pass


func get_mineral_by_id(mineral_id: String) -> MultiplayerServerAPI.Mineral:
	var idx: int = _ws.reference_body.index_of_mineral_by_id(mineral_id)
	
	if idx >= 0:
		return _ws.reference_body.minerals[idx]
	else:
		return null


func stock_of(type: String) -> int:
	if _ws.players.size() == 0:
		return -1
	
	var p = _ws.find_by_id(_ws.current_player)
	if p:
		return p.inventory.stock_of(type)
	else: return -1

func setup_client(address: String) -> Error:
	close()
	return _ws.connect_to_server(address)


func close() -> void:
	_ws.close()

func get_peers() -> Array:
	return _ws.get_players().map(func (e: MultiplayerServerAPI.PlayerData) -> int: return e.peer)


func find_id_by_peer(peer: int) -> String:
	return _ws.find_id_by_peer(peer)

func get_players() -> Array[MultiplayerServerAPI.PlayerData]:
	return _ws.get_players()

func is_remote_object(node: Node) -> bool:
	if multiplayer.has_multiplayer_peer():
		return node.is_multiplayer_authority()
	return false

func get_network_object(network_id: int) -> NetworkObjectData:
	return network_objects.get(network_id, null)


func register_network_object(n: NetworkEntity) -> void:
	assert(n != null, "")
	
	var parent: Node = n.get_parent()
	
	if parent.has_meta(&"entity_id") and parent.has_meta(&"entity_type") and parent.has_meta(&"origin_peer"):
		n._network_id = parent.get_meta(&"entity_id")
		network_objects[parent.get_meta(&"entity_id")] = n


@rpc("any_peer")
func _on_notification_event_recived(notification_event: NetworkNotification, data: Dictionary = {}) -> void:
	multiplayer_event.emit(notification_event, multiplayer.get_remote_sender_id(), data)


@rpc("any_peer")
func remote_register_network_object(object_id: int, node_name: StringName, _origin_control: NetworkEntity.OriginControl) -> void:
	#assert(not multiplayer.is_server())
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
	if waiting_network_objects_pairing.size() > 0:
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
	close()


func _on_server_disconnected() -> void:
	print("Disconnected from server")
	close()


func is_server_headless() -> bool:
	return false # To-Do: add logic to check this


func peer_is_server(peer: int) -> bool:
	return peer == SERVER_PEER

	
func connection_status() -> MultiplayerPeer.ConnectionStatus:
	if not multiplayer.has_multiplayer_peer():
		return MultiplayerPeer.CONNECTION_DISCONNECTED
	return multiplayer.multiplayer_peer.get_connection_status()


func init() -> void:
	Server.resource_collected.connect(_on_resource_collected)
	Server.planet_listed.connect(_on_planet_listed)
	Server.get_planet_list(0)
	Server.planet_status_requested.connect(_on_planet_status_requested)


func _on_planet_status_requested(p_solar_system_id, p_planet_id, data):
	planet_status_requested.emit(p_solar_system_id, p_planet_id, data)
	floating_resources_updated.emit(get_resource_from_reference_body())

func update_reference_body(planet_name: String) -> void:
	_ws.send_data(MultiplayerServerAPI.MessageType.UPDATE_REFEFERENCE_BODY, {"referenceBodyName": planet_name})

func get_planet_status(p_solar_system_id, p_planet_id, p_requester) -> void:
	Server.get_planet_status(p_solar_system_id, p_planet_id, p_requester)

func _on_planet_listed(p_solar_system_id, p_planet_ids) -> void:
	_generate_floating_resources_for_solar_system(p_solar_system_id, p_planet_ids)


func get_resource_from_reference_body() -> Array:
	return _ws.reference_body.minerals


func _generate_floating_resources_for_solar_system(p_solar_system_id, p_planet_ids) -> void:
	if _resources.has(p_solar_system_id):
		for c in get_tree().get_nodes_in_group(&"pickable_object"):
			c.queue_free()
	else:
		_resources[p_solar_system_id] = _generate_resources_for_planets(p_planet_ids)

func _generate_resources_for_planets(p_planet_ids) -> Dictionary:
	var resources: Dictionary = {}
	for planet_id in p_planet_ids:
		resources[int(planet_id)] = _generate_resources(100)
	return resources


func get_resource_for_planet(p_solar_system_id, p_planet_id, _p_resource) -> Array:
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
	print("Resource collected: id: %s - amount %s" % [resource_id, resource_amount])
	_mineral_amount += resource_amount
	resource_collection_finished.emit(resource_id, resource_amount)


func _generate_resources_for_planet(_p_planet_id) -> PlanetData:
	return null


func send_last_position(_p_user_id: String, p_position: Vector3)  -> void:
	_debug_player_pos = p_position

func get_unique_id() -> int:
	return _ws.get_unique_id()

func start_resource_collect(_p_solar_system_id: int, _p_planet_id: int, p_resource_id: String, p_player_id: String) -> void:
	_resource_selected = ResourceCollectionData.new(
		p_resource_id,
		0,
		p_player_id,
		ResourceCollectionData.CollectionType.MINERAL
		)
	
	_ws.start_collect_resource()
	resource_collection_started.emit(p_resource_id)


func start_refinery_resource(
	_p_solar_system_id: int,
	_p_planet_id: int,
	p_resource_id: String,
	p_player_id: String,
	amount: int
	) -> void:
	_resource_selected = ResourceCollectionData.new(
		p_resource_id,
		0,
		p_player_id,
		ResourceCollectionData.CollectionType.REFINED
		)
	
	_resource_selected.amount = amount
	_ws.start_refin_resource()
	resource_refined_started.emit(p_resource_id)




func arrives_on_planet(p_solar_system_id: int, p_planet_id: int, p_player_id):
	MultiplayerServer.get_planet_status(p_solar_system_id, p_planet_id, p_player_id)
	print("Arrving planet %s" % [p_planet_id])


# This should be called from server
func finish_resource_collect(_p_resource_id: int):
	pass



func _process(delta: float) -> void:
	if update_mode == UpdateMode.IDLE:
		_update(delta)



func _physics_process(delta: float) -> void:
	if update_mode == UpdateMode.PHYSICS:
		_update(delta)


func send_entity_state(from: NetworkEntity, state: Dictionary) -> void:
	var type: String = from._type
	var desialized: Dictionary = Util.serialize_dic(state)
	var id: String = from._network_id
	
	
	_ws.send_data(MultiplayerServerAPI.MessageType.UPDATE_STATE, {
		"id": from._network_id,
		"type": "PLAYER",
		"state": desialized
	})




func _update(delta: float) -> void:
	if false:#_resource_selected:
		_resource_selected.progress = _resource_selected.progress + delta
		
		if _resource_selected.type == ResourceCollectionData.CollectionType.MINERAL:
			resource_collection_progressed.emit(_resource_selected.resource_id, _resource_selected.progress)
		elif _resource_selected.type == ResourceCollectionData.CollectionType.REFINED:
			resource_refined_progress.emit(_resource_selected.resource_id, _resource_selected.progress)
		
		if _resource_selected.progress >= 1.0:
			if _resource_selected.type == ResourceCollectionData.CollectionType.REFINED:
				_mineral_amount = 0
				refined_resource += roundi(_resource_selected.amount / 2.0)
				resource_refined_finished.emit(_resource_selected.resource_id, roundi(_resource_selected.amount / 2.0))
				Server.collect_item(_resource_selected.user_id, _resource_selected.resource_id, 1, roundi(_resource_selected.amount / 2.0))
			else:
				_mineral_amount += 10
				resource_collection_finished.emit(_resource_selected.resource_id, 10)
			
			_resource_selected = null
	
	_delta_acc += delta
	
	if _delta_acc > _sync_delta:
		if connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.is_server():
			pass#_update_server_multiplayer(delta)
		else:
			update_client_network_frame.emit(delta)
		user_position_updated.emit("dummy-id", _debug_player_pos)
		_delta_acc = 0.0
		


func _on_network_property_changed() -> void:
	pass
