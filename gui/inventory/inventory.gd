class_name InventoryHUD
extends Control

signal add_machine(asset_panel: AssetPanel)

@onready var _info_panel: InfoPanel = $info_panel
@onready var _context_panel: ContextActionPanel = $right_panel/context_action_panel
@onready var _machine_asset_items = $right_panel/machine_items

var game: Game

func _ready():
	Server.inventory_updated.connect(_on_inventory_updated)
	game = get_tree().get_nodes_in_group("game")[0]

func _on_asset_panel_asset_selected(asset_id: int):
	print("Adding asset...")
	emit_signal("add_machine", asset_id)


func _on_inventory_updated(assets: Array):
	for asset in assets:
		_machine_asset_items.add_item(asset)
	pass

func _on_horizontal_items_item_selected(p_asset_panel):
	set_actions(p_asset_panel)

func set_info(p_info: PickableInfo) -> void:
	_info_panel.set_info(p_info)

func set_actions(p_action_context) -> void:
	_context_panel.set_context(p_action_context)

