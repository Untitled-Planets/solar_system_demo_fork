extends Control

@onready var _buy_ship_button = $actions/buy_ship
@onready var _add_mines_to_miner = $actions/add_mine_to_miner

var _game: Game = null

func _ready():
	_game = get_tree().get_nodes_in_group("game")[0]
	var children = $actions.get_children()
	for c in children:
		c.action_requested.connect(_on_action_requested)


func customize_menu(p_objects: Array):
	_hide_all()
	
	var tags: Array[String] = []
	for ot in p_objects:
		tags.append(ot.tag)
	_buy_ship_button.visible = "station" in tags
	_add_mines_to_miner.visible = "miner" in tags
	pass


func _show_menu_for_tag(p_tag) -> void:
	pass

func _hide_all():
	for c in [_buy_ship_button, _add_mines_to_miner]:
		c.visible = false

func _on_action_requested(p_action_id: String) -> void:
	match p_action_id:
		"buy-ship":
			_game.buy_ship()
		"mines-to-miner":
			_game.add_mines_to_miner()
