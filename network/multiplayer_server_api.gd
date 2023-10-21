extends Node
class_name MultiplayerServerAPI

class Item extends RefCounted:
	var id: String
	var stock: int
	var item_name: String
	var type: String
	var description: String = ""
	
	func _init(id: String, item_name: String, type: String, stock: int, description: String = "") -> void:
		self.id = id
		self.item_name = item_name
		self.type = type
		self.stock = stock
		self.description = description
	
	func _to_string() -> String:
		return ""


class Inventory extends RefCounted:
	var items: Array[Item] = []
	
	func push(item: Item) -> void:
		items.append(item)
	
	func has_type(type: String) -> bool:
		for i in items:
			if i.type == type:
				return true
		return false
	
	func find_by_id(item_id: String) -> Item:
		for i in items:
			if i.id == item_id:
				return i
		return null
	
	func stock_of(type: String) -> int:
		var count: int = 0
		
		for i in items:
			if i.type == type:
				count += i.stock
		
		return count

class Mineral extends RefCounted:
	signal collect_request
	
	var id: String
	var position_coordinate: Vector2
	
	func _init(id: String, coordinate: Vector2) -> void:
		self.id = id
		position_coordinate = coordinate
	
	func to_position() -> Vector3:
		return Util.unit_coordinates_to_unit_vector(position_coordinate)
	
	static func deserialize_mineral(data: Dictionary) -> Mineral:
		return Mineral.new(data["id"], Util.deserialize_vec2(data["position"]))


class PlanetData extends RefCounted:
	var id: String
	var minerals: Array = []
	
	func _init(id: String, minerals: Array = []) -> void:
		self.id = id
		self.minerals = minerals
	
	func add_minerals(new_minerals: Array) -> void:
		if new_minerals.size() == 0:
			push_error("")
		else:
			minerals.append_array(new_minerals)
	
	func index_of_mineral_by_id(mineral_id: String) -> int:
		var s: int = minerals.size()
		if s == 0:
			return -1
		elif minerals[0].id == mineral_id:
			return 0
		elif minerals[s - 1].id == mineral_id:
			return s - 1
		
		for i in range(1, minerals.size() - 2):
			if minerals[i].id == mineral_id:
				return i
		return -1
	
	func remove_mineral_from_id(mineral_id: String) -> void:
		var s: int = minerals.size()
		if s > 0:
			if minerals[0].id == mineral_id:
				minerals.remove_at(0)
			elif minerals[s - 1].id == mineral_id:
				minerals.remove_at(s - 1)
			else:
				for i in range(1, minerals.size() - 2):
					if minerals[i].id == mineral_id:
						minerals.remove_at(i)
						return


class EntityData extends  RefCounted:
	var id: String
	var peer: int
	var position: Vector3 = Vector3.ZERO

class PlayerData extends EntityData:
	var inventory: Inventory
	
	func _init(id: String, peer: int) -> void:
		self.id = id
		self.peer = peer
		inventory = Inventory.new()

class ShipData extends EntityData:
	func _init(id: String, peer: int) -> void:
		self.id = id
		self.peer = peer

enum MessageType {
	SYNC_REQUEST,
	CLIENT_CONNECTED,
	CLIENT_DISCONNECTED,
	SYNC_DATA,
	UPDATE_STATE,
	SPAWN_PLAYER,
	DESPAWN_PLAYER,
	SPAWN_SHIP,
	DESPAWN_SHIP,
	ENTER_SHIP,
	EXIT_SHIP,
	COLLECT_RESOURCE_START,
	DESPAWN_RESOURCE,
	REFIN_RESOURCE_START,
	COLLECT_RESOURCE_FINISHED,
	REFIN_RESOURCE_FINISHED,
	UPDATE_REFEFERENCE_BODY,
	PLANET_STATE
}

signal reference_body_updated(planet_data: PlanetData)
signal packet_recived(type: MessageType, data: Dictionary)

var current_player: String = ""
var _peer: int = -1
var players: Array[PlayerData] = []
var ships: Array[ShipData] = []
var reference_body: PlanetData = null


func send_data(_type: MessageType, _data: Dictionary):
	assert(false, "Implement this")

func get_unique_id() -> int:
	return _peer

func _client_connected(id: String, peer: int, _data: Dictionary) -> void:
	var new_player: PlayerData = PlayerData.new(id, peer)
	players.append(new_player)
	multiplayer.peer_connected.emit(peer)


func _client_disconnected(id: String) -> void:
	for p in range(players.size()):
		if players[p].id == id:
			var peer: int = players[p].peer
			players.remove_at(p)
			multiplayer.peer_disconnected.emit(peer)
			break

func _update_reference_body(body_id: String, mineralsData: Array) -> void:
	var minerals: Array = mineralsData.map(func (e: Dictionary) -> Mineral: return Mineral.deserialize_mineral(e)) as Array[Mineral]
	var p: PlanetData = PlanetData.new(body_id, minerals)
	reference_body = p
	reference_body_updated.emit(p)


func _server_connected(origin_id: String, peer: int, client_list: Array, _ships_list: Array) -> void:
	current_player = origin_id
	_peer = peer
	var new_player: PlayerData = PlayerData.new(origin_id, peer)
	players.append(new_player)
	for c in client_list:
		_client_connected(c.id, c.peer, c)
	multiplayer.connected_to_server.emit()


func _update_inventory(inventory: Inventory) -> void:
	find_by_id(current_player).inventory = inventory



func get_players(exclude_origin: bool = true) -> Array[PlayerData]:
	var arr: Array[PlayerData] = players.duplicate()
	if exclude_origin:
		for i in range(arr.size()):
			if arr[i].id == current_player:
				arr.remove_at(i)
				break
	return arr

func get_player() -> PlayerData:
	return find_by_id(current_player)

func find_by_peer(peer: int) -> PlayerData:
	for i in range(players.size()):
		if players[i].peer == peer:
			return players[i]
	return null

func find_id_by_peer(peer: int) -> String:
	var r: PlayerData = find_by_peer(peer)
	if r != null:
		return r.id
	else:
		return ""

func find_by_id(id: String) -> PlayerData:
	for i in range(players.size()):
		if players[i].id == id:
			return players[i]
	return null


func start_collect_resource(p_resource_id: String) -> void:
	assert(false, "Implement this")


func start_refin_resource() -> void:
	assert(false, "Implement this")


func spawn_ship() -> void:
	assert(false, "Implement this")




