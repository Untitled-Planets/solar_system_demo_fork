extends Node

#signal machine_move_requested(node_path, move_data)
signal add_machine_requested(controller_id, machine_id, planet_id, spawn_location)
signal task_requested(object_id: NodePath, task_id: String, data)
signal task_cancelled(machine_path_id: NodePath, task_id: String)

signal planet_resource_collected(machine_id: NodePath, planet_id: int, amount)
signal login_requested(p_data: Dictionary)

@onready var _request = $request

var inventory := {}
var _planets := {}

var _planet_id := "dummy"

func generate_deposits(p_planet_ids: Array[int]) -> void:
	for id in p_planet_ids:
		_generate_deposits_for_planet(id)

# in this moment generate only 3 deposits
func _generate_deposits_for_planet(p_planet_id: int) -> void:
	if not _planets.has(p_planet_id):
		var deposits := []
		for i in 3:
			var uc := Util.generate_unit_coordinates()
			deposits.append({
				pos = Vector2(uc.x * 90.0, uc.y * 360),
				amount = randi() % 1000
			})
		_planets[p_planet_id] = {
			"deposits": deposits
		}


func _call_event(p_name, params):
	get_tree().call_group(p_name, params)

func planet_travel(planet_id):
	_call_event("server_planet_traveled", planet_id)

func planet_info_refresh():
	_call_event("server_planet_info_refreshed", 0)

#func planet_get_deposits():
#	return _planets[_planet_id].deposits
#
func planet_get_deposits(planet_id: int) -> Array:
	return _planets[planet_id].deposits

func inventory_refresh():
	_call_event("server_inventory_refreshed", 0)

func miner_get_status(miner_id):
	return inventory.miners[miner_id]

func miner_spawn(controller_id, miner_id, planet_id, spawn_location: SpawnLocation):
#	_call_event("server_miner_spawn", [controller_id, miner_id, planet_id])
	await get_tree().process_frame
	server_miner_spawn(controller_id, miner_id, planet_id, spawn_location)
	return OK

func miner_attach(miner_id, planet_id, pos):
	_call_event("server_miner_attach", [OK, miner_id, planet_id, pos])
	return OK

func sign_in():
	_call_event("server_signed_in", 0)

func _ready():
	pass # Replace with function body.

func server_miner_spawn(controller_id, miner_id, planet_id, spawn_location) -> void:
	print("Checking spawn condition...")
	await get_tree().create_timer(0.1).timeout
	print("Success. Send broadcast that a player wants to spawn")
	client_miner_spawn(controller_id, miner_id, planet_id, spawn_location)

func client_miner_spawn(controller_id, miner_id, planet_id, spawn_location) -> void:
	add_machine_requested.emit(controller_id, miner_id, planet_id, spawn_location)


func generate_planet_path(from: Vector3, to: Vector3, amount: int) -> Array[Vector3]:
	var step: float = 1.0 / float(amount)
	var weight := 0.0
	var points: Array[Vector3] = []
	
	while weight < 1.0:
		var direction := from.slerp(to, weight)
		points.append(direction)
		weight += step
	return points

func machine_mine(p_machine_id, task_id: String, p_data) -> void:
	server_machine_mine(p_machine_id, task_id, p_data)

func server_machine_mine(p_machine_id, task_id: String, p_data) -> void:
	client_machine_mine(p_machine_id, task_id, p_data)

func client_machine_mine(p_machine_id, task_id: String, p_data) -> void:
	task_requested.emit(p_machine_id, task_id, p_data)

func server_machine_move(miner_node_path, task_id: String, move_data: MoveMachineData):
	client_machine_move(miner_node_path, task_id, move_data)

func client_machine_move(miner_node_path, task_id: String, p_data: MoveMachineData):
	task_requested.emit(miner_node_path, task_id, p_data)

func machine_move(miner_node_path, task_id: String, move_data: MoveMachineData):
	server_machine_move(miner_node_path, task_id, move_data)


func machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	server_machine_collect_resource(machine_id, planet_id, location_id, _mine_speed)

func server_machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	client_machine_collect_resource(machine_id, planet_id, location_id, _mine_speed)

func client_machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	var amount = _collect_resource(planet_id, location_id, _mine_speed)
	planet_resource_collected.emit(machine_id, planet_id, amount)

func cancel_task(machine_path_id: NodePath, task_name: String) -> void:
	server_cancel_task(machine_path_id, task_name)

func server_cancel_task(machine_path_id: NodePath, task_name: String) -> void:
	client_cancel_task(machine_path_id, task_name)

func client_cancel_task(machine_path_id: NodePath, task_name: String) -> void:
	task_cancelled.emit(machine_path_id, task_name)

func _collect_resource(planet_id: int, location_id: int, _mine_speed: int = 10) -> int:
	var location = _planets[planet_id].deposits[location_id]
	var amount: int = _mine_speed * 0.5
	var collected_amount: int
	if amount > location.amount:
		collected_amount = location.amount
		location.amount = 0
	else:
		collected_amount = amount
		location.amount -= amount
	return collected_amount

func get_resource_amount(planet_id: int, location_id: int) -> int:
	var deposits = _planets[planet_id].deposits
	if location_id < deposits.size():
		return _planets[planet_id].deposits[location_id].amount
	else:
		return 0.0


func join(p_username):
	_request.join(p_username)
