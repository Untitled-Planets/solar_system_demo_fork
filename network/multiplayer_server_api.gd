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

class MineralData extends RefCounted:
	var id: int
	var position: Vector2
	var disabled: bool
	
	func _init(id: int, position: Vector2, disabled: bool) -> void:
		self.id = id
		self.position = position
		self.disabled = disabled
	
	func to_position() -> Vector3:
		return Util.unit_coordinates_to_unit_vector(position)
	
	func _to_string() -> String:
		return "Mineral Data - ID: %s - POSITION: %s" % [id, position]

class PlanetData extends RefCounted:
	signal update_minerals(id: int, state: bool)
	var id: String
	var mineralManager: MineralManager
	
	var regions: int = 0
	
	func _init(id: String, mineralManager: MineralManager) -> void:
		self.id = id
		self.mineralManager = mineralManager
	
	func get_mineral_position(id: int) -> Vector2:
		return mineralManager.get_mineral_position(id)
	
	func get_available_resources() -> Array:
		var list: Array = []
		for i in range(mineralManager.amount):
			if not Util.is_bit_enable(i, mineralManager.disabledBitset):
				var mineral: MineralData = MineralData.new(i, mineralManager.get_mineral_position(i), false)
				list.append(mineral)
			else:
				print("bit %s disabled")
		return list
	
	func get_mineral_id(id: int) -> MineralData:
		if not mineralManager.exist_mineral(id):
			return null
		var is_disabled: bool = not Util.is_bit_enable(id, mineralManager.disabledBitset)
		var position: Vector2 = mineralManager.get_mineral_position(id)
		var mineral: MineralData = MineralData.new(id, position, is_disabled)
		return mineral
	
	func remove_mineral_from_id(mineral_id: int) -> void:
		var biteset: int = mineralManager.disabledBitset
		biteset = Util.toggle_bit(mineral_id, biteset)
		update_minerals.emit(mineral_id, Util.is_bit_enable(mineral_id, biteset))


class EntityData extends  RefCounted:
	var id: String
	var peer: int
	var position: Vector3 = Vector3.ZERO
	var rotation: Vector3 = Vector3.ZERO
	
	var instanced: bool = false

class PlayerData extends EntityData:
	var username: String
	var inventory: Inventory
	var sync_position: Vector3
	
	func _init(id: String, peer: int, username: String = "", instanced: bool = true) -> void:
		self.id = id
		self.peer = peer
		self.username = username
		inventory = Inventory.new()

class ShipData extends EntityData:
	var sync_position: Vector3
	var ownerId: String
	func _init(id: String, peer: int, instanced: bool, ownerId: String) -> void:
		self.id = id
		self.peer = peer
		self.instanced = instanced
		self.ownerId = ownerId
		

class MineralManager extends RefCounted:
	var seed: int
	var amount: int
	var disabledBitset: int
	
	var bitfield: BitField
	
	func _init(seed: int, amount: int, disabledBitset: Array) -> void:
		self.seed = seed
		self.amount = amount
		#self.disabledBitset = disabledBitset
		bitfield = BitField.new(amount)
		bitfield.fields = disabledBitset
	
	func update_bitset(newBitset: int) -> void:
		disabledBitset = newBitset
	
	func exist_mineral(id: int) -> bool:
		return id >= 0 and id <= amount
	
	func get_mineral_position(id: int, n_area: int = 1) -> Vector2:
		var sum: int = seed + n_area + id
		var sha256: String = String.num_uint64(sum, 16).sha256_text()
		var buffer: PackedByteArray = sha256.hex_decode()
		var x_buffer: PackedByteArray = buffer.slice(0, 2)
		var y_buffer: PackedByteArray = buffer.slice(2, 4)
		var pos: Vector2 = Vector2(
			(Util.decode_u16(y_buffer) / 32767.0) - 1,
			Util.decode_u16(x_buffer) / 65535.0
			)
		return pos
	

enum MessageType {
	AUTH_REQUEST,
	AUTH_FAIL,
	AUTH_SUCCESS,
	SYNC_REQUEST,
	CLIENT_CONNECTED,
	CLIENT_DISCONNECTED,
	SYNC_DATA,
	UPDATE_STATE,
	SPAWN_PLAYER,
	DESPAWN_PLAYER,
	BUY_SHIP,
	SPAWN_SHIP,
	DESPAWN_SHIP,
	ENTER_SHIP,
	EXIT_SHIP,
	SHIP_INTERACT_RESULT,
	COLLECT_RESOURCE_START,
	DESPAWN_RESOURCE,
	REFIN_RESOURCE_START,
	COLLECT_RESOURCE_FINISHED,
	REFIN_RESOURCE_FINISHED,
	UPDATE_REFEFERENCE_BODY,
	PLANET_STATE,
	CHAT
}

signal reference_body_updated(planet_data: PlanetData)
signal packet_recived(type: MessageType, data: Dictionary)
signal chat_message_recived(message: String, from)
signal entity_update(entity: EntityData)

var current_player: String = ""
var _peer: int = -1
var _username: String = ""
var players: Array[PlayerData] = []
var ships: Array[ShipData] = []
var reference_body: PlanetData = null
var waiting_entership_result: bool = false


func send_data(_type: MessageType, _data: Dictionary):
	assert(false, "Implement this")

func get_unique_id() -> int:
	return _peer

func _client_connected(id: String, peer: int, _data: Dictionary) -> void:
	var new_player: PlayerData = PlayerData.new(id, peer, _data["username"])
	new_player.instanced = _data["instanced"]
	players.append(new_player)
	multiplayer.peer_connected.emit(peer)


func _client_disconnected(id: String) -> void:
	for p in range(players.size()):
		if players[p].id == id:
			var peer: int = players[p].peer
			players.remove_at(p)
			multiplayer.peer_disconnected.emit(peer)
			break

func _update_reference_body(body_id: String, mineralsData: Dictionary) -> void:
	var seed: int = mineralsData["seed"]
	var amount: int = mineralsData["amount"]
	var disabledBitset: int = mineralsData["disabled"]
	
	var fieldsD: Dictionary = mineralsData["bitfield"]["fields"]
	var fields: Array = []
	var size: int = fieldsD.keys().size()
	fields.resize(size)
	
	for i in range(size):
		fields[i] = fieldsD[str(i)]
	
	var mManager: MineralManager = MineralManager.new(seed, amount, fields)
	var p: PlanetData = PlanetData.new(body_id, mManager)
	reference_body = p
	reference_body_updated.emit(p)


func _server_connected(
	origin_id: String,
	peer: int,
	client_list: Array,
	_ships_list: Array,
	sync_pos: Vector3,
	inv: Inventory
	) -> void:
	current_player = origin_id
	_peer = peer
	var new_player: PlayerData = PlayerData.new(origin_id, peer)
	new_player.position = sync_pos
	new_player.inventory = inv
	players.append(new_player)
	for c in client_list:
		if c.id == origin_id:
			new_player.instanced = c.instanced
			continue
		_client_connected(c.id, c.peer, c)
	
	for ship in _ships_list:
		var shipData: ShipData = ShipData.new(ship["id"], ship["peer"], ship["instanced"])
		shipData.position = Util.deserialize_vec3(ship["position"])
		shipData.rotation = Util.deserialize_vec3(ship["rotation"])
		ships.append(shipData)
	
	multiplayer.connected_to_server.emit()


func _update_inventory(inventory: Inventory) -> void:
	find_by_id(current_player).inventory = inventory

func get_region() -> void:
	pass

func get_minerals() -> void:
	pass

func get_players(exclude_origin: bool = true) -> Array[PlayerData]:
	var arr: Array[PlayerData] = players.duplicate()
	if exclude_origin:
		for i in range(arr.size()):
			if arr[i].id == current_player:
				arr.remove_at(i)
				break
	return arr

func get_ships() -> Array[ShipData]:
	return ships

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

func find_ship_node(id: String) -> Ship:
	for ship in get_tree().get_nodes_in_group(&"ship"):
		if ship.get_meta(&"entity_id", "") == id:
			return ship
	return null

func start_collect_resource(p_resource_id: int) -> void:
	assert(false, "Implement this")


func start_refin_resource(amount: int) -> void:
	assert(false, "Implement this")

func get_current_username() -> String:
	return get_player().username

func spawn_ship() -> void:
	assert(false, "Implement this")



