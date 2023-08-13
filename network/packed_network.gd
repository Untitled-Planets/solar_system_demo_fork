## This class is only for documentation.
## You can see it as an interface which you must implement in any class you want
## to send data through the network.
## NetworkSerializer should automatically add to a group called "network"
## and implement the methods below.

class_name NetworkEntity
extends Node


const ServerPeerId: int = 1
const NetworkGroup: StringName = &"network"

## Indicates if the control will be from the client (specified in _network_control) or from the server, in
## if the control belongs to the client, it will send the data to the server, being the authority of the client
enum OriginControl {
	SERVER = 0,
	CLIENT = 1
}

@export var origin_control: OriginControl = OriginControl.SERVER

var _peer_id: int = -1

## 
var _network_control: int = ServerPeerId : set = _set_network_control

func _set_network_control(id: int) -> void:
	set_multiplayer_authority(id)


func _ready() -> void:
	add_to_group(NetworkGroup)


func serialize() -> Dictionary:
	assert(false, "Implement this")
	return {}


func deserialize(p_data: Dictionary) -> void:
	assert(false, "Implement this")


func is_origin_control_server() -> bool:
	return origin_control == OriginControl.SERVER

