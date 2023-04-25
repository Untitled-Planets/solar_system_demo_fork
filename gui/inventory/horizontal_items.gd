class_name InventoryHorizontalItems
extends Control

signal item_selected(item_id: int)

func _ready():
	_connect_items()
	pass

func _connect_items() -> void:
	var items := $HBoxContainer.get_children()
	for index in items.size():
		var item: AssetPanel = items[index]
		item.asset_selected.connect(_on_asset_selected)


func _on_asset_selected(asset_id: int) -> void:
	item_selected.emit(asset_id)
