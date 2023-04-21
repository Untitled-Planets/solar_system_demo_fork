class_name Game
extends Node3D

@onready var _solar_system: SolarSystem = $SolarSystem
@onready var _warehouse: Warehouse = $warehouse
@onready var _asset_inventory: AssetInventory = $SolarSystem/asset_inventory

var _machine_selected: MachineCharacter = null

func _ready():
	Server.add_machine_requested.connect(_on_add_machine)
	Server.task_requested.connect(_on_task_rquested)

func get_solar_system() -> SolarSystem:
	return _solar_system

func _on_waypoint_hud_waypoint_selected(waypoint: Waypoint):
	var so = waypoint.get_selected_object()
	if so is MachineCharacter and not _machine_selected:
		_machine_selected = so
	if so is StellarBodyWrapper and _machine_selected:
#		var data := MoveMachineData.new()
#		data.from = _machine_selected.position
#		data.to = waypoint.position
#		data.machine_speed = _machine_selected.get_max_speed()
#		data.planet_radius = _solar_system.get_reference_stellar_body().radius
#		Server.move_machine(_machine_selected.get_path(), data)
		var data := Miner.MineTaskData.new()
		data.location = Util.position_to_unit_coordinates(waypoint.position)
		data.planet_id = _solar_system.get_reference_stellar_body_id()
		Server.machine_mine(_machine_selected.get_path(), "mine", data)
		_machine_selected = null

func _on_mineral_extracted(id, amount) -> void:
	_warehouse.add_item(Warehouse.ItemData.new(id, amount))

func _on_add_machine(_player_id: int, _machine_id: int, _planet_id: int, _location: SpawnLocation) -> void:
	var planet: StellarBody = _solar_system.get_reference_stellar_body()
	var spawn_point := planet.get_spawn_point()
	var asset: Node3D = _asset_inventory.generate_asset(0)
	var miner: Miner = asset as Miner
	if miner:
		planet.node.add_child(miner)
		miner.set_planet(planet)
		miner.global_position = spawn_point
		miner.configure_waypoint(_solar_system.is_planet_mode_enabled())
		miner.mineral_extracted.connect(_on_mineral_extracted)

func _on_inventory_add_machine(machine_id: int):
	Server.miner_spawn(0, machine_id, _solar_system.get_reference_stellar_body_id(), null)


func _on_task_rquested(object_id: NodePath, task_id: String, p_data) -> void:
#	print("Requesting task: ", task_id)
	var worker: IWorker = get_node(object_id)
	if worker.do_task(task_id, p_data) != OK:
		push_error("Cannot execute task {}".format(task_id))
