extends PanelContainer

signal asset_selected(asset_id)

@export var _id: int = -1

func _on_texture_button_pressed():
	emit_signal("asset_selected", _id)
