extends Control

var _game: Game = null

func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]
	var children = $actions.get_children()
	for c in children:
		c.action_requested.connect(_on_action_requested)


func _on_action_requested(p_action_id: String) -> void:
	match p_action_id:
		"buy-ship":
			_game.buy_ship()
			pass
