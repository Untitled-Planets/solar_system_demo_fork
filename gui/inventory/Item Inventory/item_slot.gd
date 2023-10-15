extends Control
class_name ItemSlot

@onready var name_label: Label = $PanelContainer/LabelName as Label
@onready var quantity_label: Label = $PanelContainer/Control/LabelQuantity as Label


func _ready() -> void:
	pass


func load_item(item_data: MultiplayerServerAPI.Item) -> void:
	name_label.text = item_data.item_name
	quantity_label.text = "x" + str(item_data.stock)
