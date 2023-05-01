class_name InventoryHUD
extends Control

signal add_machine(asset_panel: AssetPanel)

@onready var _info_panel: InfoPanel = $info_panel
@onready var _context_panel: ContextActionPanel = $right_panel/context_action_panel

var game: Game

func _ready():
	game = get_tree().get_nodes_in_group("game")[0]

func _on_asset_panel_asset_selected(asset_id: int):
	print("Adding asset...")
	emit_signal("add_machine", asset_id)


func _on_horizontal_items_item_selected(p_asset_panel):
#	print("Adding asset...")
#	emit_signal("add_machine", p_asset_panel)
	set_actions(p_asset_panel)

func set_info(p_info: PickableInfo) -> void:
	_info_panel.set_info(p_info)

func set_actions(p_action_context) -> void:
	_context_panel.set_context(p_action_context)

