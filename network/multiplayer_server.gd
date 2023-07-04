extends Node

signal resource_collection_progressed(resource_id, p_procent)
signal resource_collection_finished(resource_id)
signal resource_collection_started(resource_id)

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

var _resource_selected: ResourceCollectionData = null

#func _ready():
#	if _ws.connect_to_url("wss://localhost::9000") != OK:
#		OS.alert("Failed to connect")
#		breakpoint
	

func _initialize():
	var ssd := SolarSystemData.new()
	_solar_systems.append(ssd)

func _generate_resources_for_planet(p_planet_id) -> PlanetData:
	
	
	return null

func start_resource_collect(p_solar_system_id: int, p_planet_id: int, p_resource_id: String, p_player_id: int):
	_resource_selected = ResourceCollectionData.new()
	_resource_selected.progress = 0
	_resource_selected.resource_id = p_resource_id
	resource_collection_started.emit(p_resource_id)


func arrives_on_planet(p_solar_system_id: int, p_planet_id: int, p_player_id: int):
	print("Arrving planet {0}".format([p_planet_id]))

# This should be called from server
func finish_resource_collect(p_resource_id: int):
	pass

func _process(delta):
	if _resource_selected:
		_resource_selected.progress = _resource_selected.progress + delta
		resource_collection_progressed.emit(_resource_selected.resource_id, _resource_selected.progress)
		if _resource_selected.progress >= 1.0:
			resource_collection_finished.emit(_resource_selected.resource_id)
			_resource_selected = null
