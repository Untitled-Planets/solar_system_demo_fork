extends Node

signal resource_collection_progressed(resource_id, p_procent)
signal resource_collection_finished(resource_id)
signal resource_collection_started(resource_id)
signal users_updated(user_joining, user_leaving)
signal user_position_updated(p_user_id, player_position)
signal resources_generated(solar_system_id, planet_id ,resources)
signal planet_status_requested(solar_system_id, planet_id, data)
signal floating_resources_updated(solar_system_id, planet_id, resources)


const _30_fps_delta = 1.0 / 30.0
var _delta_acc: float = 0.0

var _resources: Dictionary = {}
var _solar_systems: Array = []
var _planet_system: Dictionary

var _ws: WebSocketPeer = WebSocketPeer.new()

class SolarSystemData:
	var id: int = -1
	var planets: Array[PlanetData] = []

class PlanetData:
	var id: int = -1
	
	# {id, unit_coordinate, amount}
	var resources: Dictionary = {}

class ResourceCollectionData:
	var resource_id: String = ""
	var progress: float
	var user_id: String = ""

var _resource_selected: ResourceCollectionData = null



func init():
	Server.resource_collected.connect(_on_resource_collected)
	Server.planet_listed.connect(_on_planet_listed)
	Server.get_planet_list(0)
	Server.planet_status_requested.connect(_on_planet_status_requested)


func _on_planet_status_requested(p_solar_system_id, p_planet_id, data):
	planet_status_requested.emit(p_solar_system_id, p_planet_id, data)
	_generate_resources_for_planets([int(p_planet_id)])
#	floating_resources_updated.emit(p_solar_system_id, p_planet_id, _resources[int(p_planet_id)])
	

func get_planet_status(p_solar_system_id, p_planet_id, p_requester):
	Server.get_planet_status(p_solar_system_id, p_planet_id, p_requester)

func _on_planet_listed(p_solar_system_id, p_planet_ids) -> void:
	_generate_floating_items_for_solar_system(p_solar_system_id, p_planet_ids)
	pass

func _generate_floating_items_for_solar_system(p_solar_system_id, p_planet_ids) -> void:
	if _resources.has(p_solar_system_id):
		# clean
		pass
	else:
		_resources[p_solar_system_id] = _generate_resources_for_planets(p_planet_ids)

func _generate_resources_for_planets(p_planet_ids) -> Dictionary:
	var resources := {}
	for planet_id in p_planet_ids:
		resources[int(planet_id)] = _generate_resources(100)
	return resources


func get_resource_for_planet(p_solar_system_id, p_planet_id, p_resource) -> Array:
	return _resources[p_solar_system_id][p_planet_id]

func _generate_resources(p_amount: int) -> Array:
	var rs := []
	for index in p_amount:
		# use dictionary for now
		rs.append({
			uuid = "",
			type = 0,
			unit_coordinates = {
				x = randf_range(-1, 1),
				y = randf_range(0, 1)
			}
		})
	
	return rs


func join() -> String:
	var id: String = "dummy-id"
	users_updated.emit([id], [])
	return id


func _initialize():
	var ssd := SolarSystemData.new()
	_solar_systems.append(ssd)


func _on_resource_collected(resource_id: String, resource_amount: int):
	resource_collection_finished.emit(resource_id)

func _generate_resources_for_planet(p_planet_id) -> PlanetData:
	return null

var _debug_player_pos: Vector3

func send_last_position(p_user_id: String, p_position: Vector3):
	_debug_player_pos = p_position

func start_resource_collect(p_solar_system_id: int, p_planet_id: int, p_resource_id: String, p_player_id: String):
	_resource_selected = ResourceCollectionData.new()
	_resource_selected.progress = 0
	_resource_selected.resource_id = p_resource_id
	_resource_selected.user_id = p_player_id
	resource_collection_started.emit(p_resource_id)


func arrives_on_planet(p_solar_system_id: int, p_planet_id: int, p_player_id):
	MultiplayerServer.get_planet_status(p_solar_system_id, p_planet_id, p_player_id)
	print("Arrving planet {0}".format([p_planet_id]))

# This should be called from server
func finish_resource_collect(p_resource_id: int):
	pass

func _process(delta):
	if _resource_selected:
		_resource_selected.progress = _resource_selected.progress + delta
		resource_collection_progressed.emit(_resource_selected.resource_id, _resource_selected.progress)
		if _resource_selected.progress >= 1.0:
			Server.collect_item(_resource_selected.user_id, _resource_selected.resource_id, 1, 10)
			_resource_selected = null
	
	_delta_acc += delta
	if _delta_acc > _30_fps_delta:
		user_position_updated.emit("dummy-id", _debug_player_pos)
		_delta_acc = 0.0
