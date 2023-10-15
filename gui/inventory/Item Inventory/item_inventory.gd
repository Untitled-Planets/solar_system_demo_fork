extends Control

const ITEM_SLOT: PackedScene = preload("res://gui/inventory/Item Inventory/item_slot.tscn")

@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/ScrollContainer/GridContainer as GridContainer

func _ready() -> void:
	clear()
	MultiplayerServer.inventory_updated.connect(load_inventory)


func clear() -> void:
	for c in grid_container.get_children():
		c.queue_free()


func load_inventory(items: Array[MultiplayerServerAPI.Item]) -> void:
	clear()
	for i in range(items.size()):
		var item: ItemSlot = ITEM_SLOT.instantiate()
		grid_container.add_child(item)
		item.load_item(items[i])
