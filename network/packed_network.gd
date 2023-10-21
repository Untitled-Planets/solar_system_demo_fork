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

enum SyncMode {
	UPDATE,
	FRAME
}



@export var entity_owner: Node = null
## List of properties that will be updating over the network
@export var properties_sync: Array[StringName] = []
@export var origin_control: OriginControl = OriginControl.SERVER
@export var sync_mode: SyncMode = SyncMode.UPDATE

var _network_id: String = "";
var _type: String = "";
var _last_state: Dictionary = {}
## List of properties that will be updating over the network
var _network_control: int = ServerPeerId : set = _set_network_control
var _is_registered_network: bool = false


## The current planet the entity target is on. It is used by Multiplayer Server Singleton
var current_planet


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
	print("Multiplayer authority: " + str(get_multiplayer_authority()))
	
	if get_multiplayer_authority() != MultiplayerServer._ws._peer:
		set_process(false)


func _process(_delta: float) -> void:
	if properties_sync.size() == 0:
		return
	
	if Engine.get_process_frames() % 4 == 0:
		return
	
	var current_state: Dictionary = {}
	var changed_values: Dictionary = {}
	
	for p in properties_sync:
		var value: Variant = entity_owner.get(p)
		var _last_val: Variant = _last_state[p]
		if value != _last_val:
			changed_values[p] = value
		current_state[p] = value
	
	_last_state = current_state
	
	if sync_mode == SyncMode.UPDATE:
		if not changed_values.is_empty():
			properties_changed.emit(changed_values, self)
			MultiplayerServer.send_entity_state(self, changed_values)
	elif sync_mode == SyncMode.FRAME:
		MultiplayerServer.send_entity_state(self, current_state)


func _on_data_recived(packet_data: Dictionary, _sync_response: bool = false) -> void:
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
		if k == "global_position":
			if entity_owner is Character:
				var diff: float = entity_owner.global_position.distance_squared_to(packet_data[k])
				if entity_owner.is_remote_controller() and diff < (5 * 5):
					var r: RemoteController = entity_owner.get_controller()
					r.set_remote_position(packet_data[k])
					continue
		elif k == "global_transform":
			if entity_owner is Ship:
				entity_owner.global_transform = packet_data[k]
				entity_owner._visual_root.global_transform = packet_data[k]
				continue
		entity_owner.set(k, packet_data[k])


## @expermiental
## @deprecated
func serialize() -> Dictionary:
	#assert(false, "Implement this")
	return {}


## @expermiental
## @deprecated
func deserialize(_p_data: Dictionary) -> void:
	#assert(false, "Implement this")
	pass


## @expermiental
func is_origin_control_server() -> bool:
	return origin_control == OriginControl.SERVER

