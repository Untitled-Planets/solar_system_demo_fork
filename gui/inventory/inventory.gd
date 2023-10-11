class_name InventoryHUD
extends Control

signal add_machine(asset_panel: AssetPanel)

@onready var _info_panel: InfoPanel = $info_panel
@onready var _context_panel: ContextActionPanel = $right_panel/context_action_panel
@onready var _machine_items = $right_panel/machine_items

var _game: Game
var _machine_selected: MachineCharacter = null

func _ready():
	Server.inventory_updated.connect(_on_inventory_updated)
#	Server.planet_status_requested.connect(_on_planet_status_requested)
	_game = get_tree().get_first_node_in_group(&"game")


func _on_asset_panel_asset_selected(asset_id: int):
	print("Adding asset...")
	add_machine.emit(asset_id)


#func _on_planet_status_requested(solar_system_id: int, planet_id: int, data: Dictionary):
#	return
#	for md in data.machines:
#		var mid: int = md.id
#		_machine_items.add_instance_item(md)


#func _process(delta):
#	if _machine_selected:
#
#	pass

func _on_inventory_updated(p_data: Dictionary):
	for asset in p_data.instances:
		_machine_items.add_asset_item(asset)

func add_instance_item(_instance: MachineCharacter) -> void:
	pass


func _on_horizontal_items_item_selected(p_asset_panel):
	var m: MachineCharacter = _game.get_machine(p_asset_panel.get_id())
	var dac: DynamicActionContext = DynamicActionContext.new()
	dac.add_actions(p_asset_panel.get_actions())
	if m != null:
		dac.add_actions(m.get_actions())
	set_actions(dac)

func set_info(p_info: PickableInfo) -> void:
	_info_panel.set_info(p_info)

func set_actions(p_action_context) -> void:
	_context_panel.set_context(p_action_context)



func _on_machine_items_item_instance_selected(instance_panel):
	_game.machine_instance_from_ui_selected.emit(instance_panel.get_id())
