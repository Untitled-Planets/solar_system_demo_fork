extends Control

@onready var mineral_count: Label = $PanelContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer/MineralCount
@onready var refined_count: Label = $PanelContainer/VBoxContainer/CenterContainer2/VBoxContainer/HBoxContainer2/RefindeCount
#@onready var progress_bar: ProgressBar = $PanelContainer/VBoxContainer/CenterContainer/ProgressBar as ProgressBar
@onready var inventory: InventoryCharacter = $PanelContainer/VBoxContainer/CenterContainer/ItemInventory as InventoryCharacter


var _game: Game = null



func _ready() -> void:
	MultiplayerServer.resource_refined_started.connect(_refine_resource_started)
	MultiplayerServer.resource_refined_progress.connect(_refine_resource_progress)
	MultiplayerServer.inventory_updated.connect(_refine_resource_finished)
	
	visibility_changed.connect(func ():
		if visible:
			mineral_count.text = str(MultiplayerServer._mineral_amount)
			refined_count.text = str(MultiplayerServer.refined_resource)
		)
	
	await get_tree().physics_frame
	
	_game = get_tree().get_first_node_in_group(&"game")





func _refine_resource_started(resource_id: String) -> void:
	pass#progress_bar.value = 0.0


func _refine_resource_progress(resource_id: String, progress: float) -> void:
	pass#progress_bar.value = progress


func _refine_resource_finished(items) -> void:
	inventory.clear_items()
	$PanelContainer/VBoxContainer/CenterContainer3/Button.disabled = false


func _on_button_pressed() -> void:
	var stock: int = inventory.stock_of("coal")
	if stock > 0:
		MultiplayerServer.start_refinery_resource(0, _game.get_solar_system().get_reference_stellar_body_id(), "", _game._username, stock)
		$PanelContainer/VBoxContainer/CenterContainer3/Button.disabled = true

