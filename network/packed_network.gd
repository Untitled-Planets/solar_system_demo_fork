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
## List of properties that will be updating over the network
@export var properties_sync: Array[StringName] = []
@export var origin_control: OriginControl = OriginControl.SERVER

var _network_object_id: int = -1
var _last_state: Dictionary = {}
## List of properties that will be updating over the network
var _network_control: int = ServerPeerId : set = _set_network_control
var _is_registered_network: bool = false


## The current planet the entity target is on. It is used by Multiplayer Server Singleton
var current_planet


var _waiting_sync: bool = false
var _waiting_sync_states: Array[Dictionary] = []


func ASSERT_VALID_PROPERTY(value: Variant) -> void:
	var type: int = typeof(value)
	assert(type != TYPE_OBJECT and type != TYPE_SIGNAL and type != TYPE_CALLABLE, "The value is of an invalid type such as Object, Signal or Callable")

func ASSERT_PROPERTY_EXIST(property: StringName) -> void:
	assert(properties_sync.has(property), "The property %s does not exist in the list of properties that can be synchronized")



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
		ASSERT_VALID_PROPERTY(value)
		_last_state[p] = value
	
	MultiplayerServer.register_network_object(self)
	
	if not is_multiplayer_authority():
		request_authority_parameters()


func _process(_delta: float) -> void:
	#if not _is_registered_network: return
	if properties_sync.size() == 0:
		return
	
	if not is_multiplayer_authority():
		if Engine.get_process_frames() % 2 == 0:
			pass#print("Current Entity not is the owner " + entity_owner.name)
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
		_on_data_recived.rpc(changed_values)


## Request the authority to send you the current data to keep them updated
func request_authority_parameters() -> void:
	assert(not is_multiplayer_authority())
	_waiting_sync = true
	_on_request_data_parameters.rpc_id(get_multiplayer_authority())


@rpc("any_peer", "unreliable_ordered")
func _on_data_recived(packet_data: Dictionary, sync_response: bool = false) -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	if sender != get_multiplayer_authority():
		return
	
	if _waiting_sync and not sync_response:
		_waiting_sync_states.append(packet_data)
		return
	elif sync_response:
		set_properties(packet_data)
		_waiting_sync = false
		if _waiting_sync_states.size() > 0:
			for p in _waiting_sync_states:
				set_properties(p)
	else:
		set_properties(packet_data)


@rpc("any_peer")
func _on_request_data_parameters() -> void:
	var sender: int = multiplayer.get_remote_sender_id()
	_on_data_recived.rpc_id(sender, get_sync_properties(), true)


## Gets a dictionary of property values ​​that are network-synchronized
func get_sync_properties() -> Dictionary:
	var data: Dictionary = {}
	
	for p in properties_sync:
		var value: Variant = entity_owner.get(p)
		ASSERT_VALID_PROPERTY(value)
		data[p] = value
	
	return data


## Establishes the properties according to the packet data and that these exist in the list that can be synchronized
func set_properties(packet_data: Dictionary) -> void:
	for k in packet_data.keys():
		ASSERT_PROPERTY_EXIST(k)
		if k == &"global_position":
			if entity_owner is Character:
				var diff: float = entity_owner.global_position.distance_squared_to(packet_data[k])
				if entity_owner.is_remote_controller() and diff < (10 * 10):
					var r: RemoteController = entity_owner.get_controller()
					r.set_remote_position(packet_data[k])
					continue
		entity_owner.set(k, packet_data[k])


## @expermiental
## @deprecated
func serialize() -> Dictionary:
	return {}
	assert(false, "Implement this")
	return {}


## @expermiental
## @deprecated
func deserialize(p_data: Dictionary) -> void:
	return
	assert(false, "Implement this")


## @expermiental
func is_origin_control_server() -> bool:
	return origin_control == OriginControl.SERVER

