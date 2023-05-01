class_name InventoryMachineItems
extends Control

signal item_selected(asset_panel)

var _game: Game

func _ready():
	await get_tree().process_frame
	_game = get_parent().get_parent().game
	_connect_items()
	pass

func _connect_items() -> void:
	var items := $ScrollContainer/VBoxContainer.get_children()
	for index in items.size():
		var item: AssetPanel = items[index]
		item.asset_selected.connect(_on_asset_selected)
		item.set_game_ref(_game)


func _on_asset_selected(p_asset: AssetPanel) -> void:
	item_selected.emit(p_asset)
