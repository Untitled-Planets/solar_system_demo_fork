extends Control

var _game: Game = null

func _ready() -> void:
	_game = get_tree().get_first_node_in_group(&"game")
	
	add_to_group(&"portal_menu")



func _on_action_button_action_requested(action_id) -> void:
	_game.buy_ship()
