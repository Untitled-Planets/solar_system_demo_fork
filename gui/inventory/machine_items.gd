class_name InventoryMachineItems
extends Control

signal item_selected(asset_panel)
signal item_instance_selected(istance_panel)

@onready var _assets = $VBoxContainer/AssetsScroll/VBoxContainer
@onready var _instances = $VBoxContainer/InstancesScroll/VBoxContainer

@export var _asset_panel_scene: PackedScene = null
@export var _instance_panel_scene: PackedScene = null

var _game: Game

func _ready():
	await get_tree().process_frame
	_game = get_parent().get_parent()._game

func _connect_items() -> void:
	var items := $ScrollContainer/VBoxContainer.get_children()
	for index in items.size():
		var item: AssetPanel = items[index]
		item.asset_selected.connect(_on_asset_selected)
		item.set_game_ref(_game)

func add_asset_item(p_item: Dictionary) -> void:
	var instance = _asset_panel_scene.instantiate()
	_assets.add_child(instance)
	instance.asset_selected.connect(_on_asset_selected)
	instance.set_game_ref(_game)
	instance.set_id(p_item.id)
	instance.text = p_item.name

func add_instance_item(p_item: Dictionary) -> void:
	var instance = _instance_panel_scene.instantiate()
	_assets.add_child(instance)
	instance.instance_selected.connect(_on_instance_selected)      
	instance.set_game_ref(_game)
	instance.set_id(p_item.id)
	instance.text = p_item.name

func _on_asset_selected(p_asset: AssetPanel) -> void:
	item_selected.emit(p_asset)

func _on_instance_selected(p_instance: InstancePanel) -> void:
	item_instance_selected.emit(p_instance)
