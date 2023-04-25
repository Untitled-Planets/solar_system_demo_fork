extends Control

signal add_machine(machine_id)

func _on_asset_panel_asset_selected(asset_id: int):
	print("Adding asset...")
	emit_signal("add_machine", asset_id)


func _on_horizontal_items_item_selected(item_id):
#	print("Adding asset...")
	emit_signal("add_machine", item_id)
	pass # Replace with function body.
