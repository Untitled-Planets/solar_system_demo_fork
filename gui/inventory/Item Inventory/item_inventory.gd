extends Control
class_name InventoryCharacter

const ITEM_SLOT: PackedScene = preload("res://gui/inventory/Item Inventory/item_slot.tscn")

@export var max_size: int = 256
@export var valid_types: PackedStringArray = []
@export var show_title: bool = true

@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/ScrollContainer/GridContainer as GridContainer
@onready var summon_ship: Button = $PanelContainer/VBoxContainer/CenterContainer/Button as Button

var current_selected: ItemSlot = null: set = set_current_selected

func set_current_selected(new_item_slot: ItemSlot) -> void:
	if current_selected != null:
		current_selected.unselected()
	if new_item_slot:
		new_item_slot.selected()
	
	current_selected = new_item_slot

func _ready() -> void:
	if not show_title:
		$PanelContainer/VBoxContainer/Label.hide()
	
	summon_ship.hide()
	summon_ship.pressed.connect(_on_summon_ship_pressed)
	
	clear()
	for i in range(max_size):
		add_item(null)


func clear() -> void:
	for c in grid_container.get_children():
		c.queue_free()

func clear_items() -> void:
	set_current_selected(null)
	for c in grid_container.get_children():
		if c is ItemSlot:
			c.clear_item()


func set_item(item: MultiplayerServerAPI.Item, idx: int) -> void:
	if idx >= 0 and idx < grid_container.get_children().size():
		grid_container.get_children()[idx].load_item(item)


func remove_item(idx: int) -> void:
	if idx >= 0 and idx < grid_container.get_children().size():
		get_children()[idx].clear_item()


func add_item(item: MultiplayerServerAPI.Item) -> void:
	if get_inventory_size() >= max_size:
		return
	elif item != null and valid_types.size() > 0 and not valid_types.has(item.type):
		return
	
	var item_slot: ItemSlot = ITEM_SLOT.instantiate()
	grid_container.add_child(item_slot)
	item_slot.load_item(item)
	item_slot.pressed.connect(_on_item_slot_pressed)


func load_inventory(items: Array[MultiplayerServerAPI.Item]) -> void:
	clear_items()
	for i in range(items.size()):
		if valid_types.size() > 0:
			if not valid_types.has(items[i].type):
				continue
		
		if i >= grid_container.get_children().size():
			var item: ItemSlot = ITEM_SLOT.instantiate()
			grid_container.add_child(item)
			item.load_item(items[i])
			item.pressed.connect(_on_item_slot_pressed)
		else:
			grid_container.get_children()[i].load_item(items[i])


func stock_of(type: String) -> int:
	var stock: int = 0
	
	for slot in grid_container.get_children():
		if slot is ItemSlot:
			var item: MultiplayerServerAPI.Item = slot.get_item_data()
			if item != null and item.type == type:
				stock += item.stock
	
	return stock



func get_inventory_size() -> int:
	return grid_container.get_children().size()


func _on_item_slot_pressed(item_id: String, item_slot: ItemSlot) -> void:
	if item_slot != null:
		current_selected = item_slot

func _on_summon_ship_pressed() -> void:
	var raycast: RayCast3D = get_tree().get_first_node_in_group(&"spawn_ship_ray") as RayCast3D
	
	if raycast.is_colliding():
		var point: Vector3 = raycast.get_collision_point()
		MultiplayerServer.summon_ship(point)
	else:
		OS.alert("Can't spawn ship in this position")
