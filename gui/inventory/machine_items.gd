class_name InventoryMachineItems
extends Control

signal item_selected(asset_panel)

@onready var _items = $ScrollContainer/VBoxContainer

@export var _asset_panel_scene: PackedScene = null

var _game: Game

func _ready():
	await get_tree().process_frame
	_game = get_parent().get_parent().game

func _connect_items() -> void:
	var items := $ScrollContainer/VBoxContainer.get_children()
	for index in items.size():
		var item: AssetPanel = items[index]
		item.asset_selected.connect(_on_asset_selected)
		item.set_game_ref(_game)

func add_item(p_item: Dictionary) -> void:
	var instance = _asset_panel_scene.instantiate()
	_items.add_child(instance)
	instance.asset_selected.connect(_on_asset_selected)
	instance.set_game_ref(_game)
	instance.set_id(p_item.id)
	instance.text = p_item.name


func _on_asset_selected(p_asset: AssetPanel) -> void:
	item_selected.emit(p_asset)
