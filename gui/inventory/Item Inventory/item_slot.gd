extends Control
class_name ItemSlot

signal pressed(item_id: String, item_slot: ItemSlot)

@export_range(0, 999, 1, "or_greater") var min_slot: int = 0

@onready var name_label: Label = $PanelContainer/LabelName as Label
@onready var quantity_label: Label = $PanelContainer/Control/LabelQuantity as Label


var _id: String = ""

func _ready() -> void:
	unselected()


func get_item_data() -> MultiplayerServerAPI.Item:
	return MultiplayerServer.get_item_by_id(_id)


func selected() -> void:
	$ColorRect.visible = true

func unselected() -> void:
	$ColorRect.visible = false

func _get_drag_data(at_position: Vector2) -> Variant:
	if _id == "":
		return null
	else:
		return {"last_slot": self, "item_id": _id}

func _can_drop_data(at_position: Vector2, data) -> bool:
	if typeof(data) == TYPE_DICTIONARY:
		return true
	else:
		return false

func clear_item() -> void:
	name_label.text = ""
	quantity_label.text = ""
	_id = ""

func _drop_data(at_position, data: Variant) -> void:
	data["last_slot"].clear_item()
	data["last_slot"].unselected()
	
	if _id != "":
		data["last_slot"].load_item(MultiplayerServer.get_item_by_id(_id))
	
	load_item(MultiplayerServer.get_item_by_id(data["item_id"]))
	selected()



func load_item(item_data: MultiplayerServerAPI.Item) -> void:
	if item_data == null:
		clear_item()
	else:
		name_label.text = item_data.item_name
		quantity_label.text = "x" + str(item_data.stock)
		_id = item_data.id



func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			pressed.emit(_id, self)
