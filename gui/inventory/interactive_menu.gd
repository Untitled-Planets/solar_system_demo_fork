extends Control

@onready var _buy_ship_button = $actions/buy_ship
@onready var _add_mines_to_miner = $actions/add_mine_to_miner

var _game: Game = null

func _ready() -> void:
	_game = get_tree().get_first_node_in_group(&"game")
	var children = $actions.get_children()
	for c in children:
		c.action_requested.connect(_on_action_requested)


func _process(_delta: float) -> void:
	pass#if visible and Input.is_key_pressed(KEY_B):
		#_game.buy_ship()


func customize_menu(p_objects: Array):
	_hide_all()
	
	var tags: Array[String] = []
	for ot in p_objects:
		tags.append(ot.tag)
	_buy_ship_button.visible = "station" in tags
	_add_mines_to_miner.visible = "miner" in tags


func _show_menu_for_tag(p_tag) -> void:
	pass

func _hide_all():
	for c in [_buy_ship_button, _add_mines_to_miner]:
		c.visible = false

func _on_action_requested(p_action_id: String) -> void:
	match p_action_id:
		"buy-ship":
			_game.buy_ship(Vector3.ZERO)
		"mines-to-miner":
			_game.add_mines_to_miner()
