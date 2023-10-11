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


class Inventory extends RefCounted:
	var items: Array[Item] = []
	
	func push(item: Item) -> void:
		items.append(item)
	
	func has_type(type: String) -> bool:
		for i in items:
			if i.type == type:
				return true
		return false
	
	
	func stock_of(type: String) -> int:
		var count: int = 0
		
		for i in items:
			if i.type == type:
				count += i.stock
		
		return count


class PlayerData extends RefCounted:
	var id: String
	var peer: int
	var inventory: Inventory
	
	func _init(id: String, peer: int) -> void:
		self.id = id
		self.peer = peer
		inventory = Inventory.new()

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
	REFIN_RESOURCE_START,
	COLLECT_RESOURCE_FINISHED,
	REFIN_RESOURCE_FINISHED,
}

signal packet_recived(type: MessageType, data: Dictionary)

var current_player: String = ""
var _peer: int = -1
var players: Array[PlayerData] = []


func send_data(type: MessageType, data: Dictionary):
	assert(false, "Implement this")

func get_unique_id() -> int:
	return _peer


func _client_connected(id: String, peer: int, _data: Dictionary) -> void:
	var new_player: PlayerData = PlayerData.new(id, peer)
	players.append(new_player)
	multiplayer.peer_connected.emit(peer)


func _server_connected(origin_id: String, peer: int, client_list: Array, ships_list: Array) -> void:
	current_player = origin_id
	_peer = peer
	var new_player: PlayerData = PlayerData.new(origin_id, peer)
	players.append(new_player)
	multiplayer.connected_to_server.emit()
	for c in client_list:
		_client_connected(c.id, c.peer, c)


func _update_inventory(inventory: Inventory) -> void:
	find_by_id(current_player).inventory = inventory
	
	


func find_by_peer(peer: int) -> PlayerData:
	for i in range(players.size()):
		if players[i].peer == peer:
			return players[i]
	return null


func find_by_id(id: String) -> PlayerData:
	for i in range(players.size()):
		if players[i].id == id:
			return players[i]
	return null


func start_collect_resource() -> void:
	assert(false, "Implement this")


func start_refin_resource() -> void:
	assert(false, "Implement this")


func spawn_ship() -> void:
	assert(false, "Implement this")




