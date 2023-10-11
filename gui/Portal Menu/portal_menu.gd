extends Control

var _game: Game = null

var _current_portal_info: PortalInfo

func _ready() -> void:
	_game = get_tree().get_first_node_in_group(&"game")
	
	add_to_group(&"portal_menu")


func show_ui(portal_data: PortalInfo) -> void:
	assert(portal_data != null)
	_current_portal_info = portal_data
	show()


func hide_ui() -> void:
	_current_portal_info = null
	hide()



func _on_action_button_action_requested(_action_id) -> void:
	_game.buy_ship(_current_portal_info.spawn_ship_position)
