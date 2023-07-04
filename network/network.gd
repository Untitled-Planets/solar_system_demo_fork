class_name Network
extends Node

@export var _port: int = 12345
@export var _url: String = "localhost"

var _game: Game = null
var _max_connections: int = 2

func _ready():
	_game = get_parent()

func start(p_as_server: bool):
	
	var multi := ENetMultiplayerPeer.new()
	if p_as_server:
		multi.peer_connected.connect(_on_player_connected)
		multi.peer_disconnected.connect(_on_player_disconnected)
		multi.create_server(_port)
		_on_player_connected(1)
	else:
		multi.peer_connected.connect(_on_player_connected)
		multi.peer_disconnected.connect(_on_player_disconnected)
		multi.create_client(_url, _port)
	pass
	
	multiplayer.multiplayer_peer = multi


func _on_player_connected(p_player_id: int):
	_game.spawn_player_with_id(p_player_id)

func _on_player_disconnected(p_player_id: int):
	_game.remove_player(p_player_id)
