class_name InventoryHUD
extends Control

signal add_machine(machine_id)

@onready var _info_panel: InfoPanel = $info_panel
@onready var _context_panel: ContextActionPanel = $right_panel/context_action_panel

func _on_asset_panel_asset_selected(asset_id: int):
	print("Adding asset...")
	emit_signal("add_machine", asset_id)


func _on_horizontal_items_item_selected(item_id):
#	print("Adding asset...")
	emit_signal("add_machine", item_id)
	pass # Replace with function body.

func set_info(p_info: PickableInfo) -> void:
	_info_panel.set_info(p_info)
	pass

func set_actions(p_actions) -> void:
	_context_panel.set_context(p_actions)
