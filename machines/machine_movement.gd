class_name MachineMovement
extends Node

@onready var machine: MachineCharacter = get_parent() as MachineCharacter

func _ready():
	pass

func _process(delta):
	pass

# Target is the coordinate in latitude and longitude.
func perform_movement(target: Vector2):
	
	pass

func get_self_coordinates() -> Vector2:
	return Vector2();
