extends "res://gui/inventory/Item Inventory/item_inventory.gd"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	MultiplayerServer.inventory_updated.connect(load_inventory)
	load_inventory(MultiplayerServer.get_inventory())
