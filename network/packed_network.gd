# This class is only for documentation.
# You can see it as an interface which you must implement in any class you want
# to send data through the network.

# NetworkSerializer should automatically add to a group called "network"
# and implement the methods below.

class_name PackedNetwork
extends Node


func _ready():
	add_to_group("network")

func serialize() -> Dictionary:
	assert(false, "Implement this")
	return {}

func deserialize(p_data: Dictionary) -> void:
	assert(false, "Implement this")
