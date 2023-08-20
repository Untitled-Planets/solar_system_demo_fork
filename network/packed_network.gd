## This class is only for documentation.
## You can see it as an interface which you must implement in any class you want
## to send data through the network.
## NetworkSerializer should automatically add to a group called "network"
## and implement the methods below.

class_name NetworkEntity
extends Node


signal properties_changed(properties: Dictionary, origin_network_entity)

const ServerPeerId: int = 1
const NetworkGroup: StringName = &"network"

## Indicates if the control will be from the client (specified in _network_control) or from the server, in
## if the control belongs to the client, it will send the data to the server, being the authority of the client
enum OriginControl {
	SERVER = 0,
	CLIENT = 1
}

@export var entity_owner: Node = null
@export var properties_sync: Array[StringName] = []
@export var origin_control: OriginControl = OriginControl.SERVER

var _network_object_id: int = -1
var _last_state: Dictionary = {}
## 
var _network_control: int = ServerPeerId : set = _set_network_control
var _is_registered_network: bool

var current_planet



func _set_network_control(id: int) -> void:
	set_multiplayer_authority(id)


func _ready() -> void:
	add_to_group(NetworkGroup)
	assert(entity_owner != null)
	
	var properties: Array = entity_owner.get_property_list().map(
		func (e: Dictionary) -> StringName: return e["name"]
		)
	
	for p in properties_sync:
		assert(properties.has(p), "%s not has in the properties owner list" % p)
		var value: Variant = entity_owner.get(p)
		var type: int = typeof(value)
		assert(type != TYPE_OBJECT and type != TYPE_SIGNAL and type != TYPE_CALLABLE)
		_last_state[p] = value
	
	MultiplayerServer.register_network_object(self)


func _process(_delta: float) -> void:
	if not _is_registered_network or properties_sync.size() == 0:
		return
	
	if not is_multiplayer_authority():
		return
	
	var current_state: Dictionary = {}
	var changed_values: Dictionary
	
	for p in properties_sync:
		var value: Variant = entity_owner.get(p)
		var _last_val: Variant = _last_state[p]
		if value != _last_val:
			changed_values[p] = value
		current_state[p] = value
	
	_last_state = current_state
	
	if not changed_values.is_empty():
		properties_changed.emit(changed_values, self)


func serialize() -> Dictionary:
	
	assert(false, "Implement this")
	return {}


func deserialize(p_data: Dictionary) -> void:
	assert(false, "Implement this")


func is_origin_control_server() -> bool:
	return origin_control == OriginControl.SERVER

