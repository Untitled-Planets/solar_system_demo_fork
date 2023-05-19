extends Node

#signal machine_move_requested(node_path, move_data)
signal add_machine_requested(controller_id, planet_id, machine_asset_id, machine_instance_id)
signal task_requested(object_id: NodePath, task_id: String, data)
signal task_cancelled(solar_system_id: int, planet_id: int, machine_id: int, task_id: int, requester_id: String)

signal planet_resource_collected(machine_id: NodePath, planet_id: int, amount)
signal login_requested(p_data: Dictionary)

signal solar_system_requested(p_data: Dictionary)
signal planet_status_requested(solar_system_id, planet_id, data)
signal execute_task_requested(solar_system_id, planet_id, machine_id, requester_id, task_data)

@onready var _request = $request

var inventory := {}
var _planets := {}

func update_planet_deposits(solar_system_id: int, p_planet_id: int, p_points: Array):
	if not _planets.has(p_planet_id):
		_planets[p_planet_id] = {}
	var dps := []
	for p in p_points:
		dps.append({
			pos = Vector2(p.location.x * 90.0, p.location.y * 360.0),
			amount = p.amount
		})
	_planets[p_planet_id]["deposits"] = dps


func _call_event(p_name, params):
	get_tree().call_group(p_name, params)

func planet_travel(planet_id):
	_call_event("server_planet_traveled", planet_id)

func planet_info_refresh():
	_call_event("server_planet_info_refreshed", 0)


func planet_get_deposits(planet_id: int) -> Array:
	if _planets.has(planet_id):
		return _planets[planet_id].deposits
	return []

func inventory_refresh():
	_call_event("server_inventory_refreshed", 0)

func miner_get_status(miner_id):
	return inventory.miners[miner_id]

func miner_spawn(solar_system_id, planet_id, requester_id: String, machine_asset_id: int):
	_request.spawn_machine(solar_system_id, planet_id, requester_id, machine_asset_id)
	return OK

func miner_attach(miner_id, planet_id, pos):
	_call_event("server_miner_attach", [OK, miner_id, planet_id, pos])
	return OK

func sign_in():
	_call_event("server_signed_in", 0)

func _ready():
	pass # Replace with function body.

func server_miner_spawn(controller_id, miner_asset_id, machine_instance_id, planet_id, spawn_location) -> void:
	await get_tree().create_timer(0.1).timeout
	client_miner_spawn(controller_id, miner_asset_id, machine_instance_id, planet_id)

func client_miner_spawn(controller_id, planet_id, miner_asset_id, machine_instance_id) -> void:
	add_machine_requested.emit(controller_id, planet_id, miner_asset_id, machine_instance_id)


func generate_planet_path(from: Vector3, to: Vector3, amount: int) -> Array[Vector3]:
	var step: float = 1.0 / float(amount)
	var weight := 0.0
	var points: Array[Vector3] = []
	
	while weight < 1.0:
		var direction := from.slerp(to, weight)
		points.append(direction)
		weight += step
	return points

func machine_mine(p_solar_system_id: int, p_planet_id, p_machine_id: int, p_requester_id: String, task_name: String, p_data) -> void:
	var data := {
		task_name = task_name,
		location = {
			x = p_data.location.x,
			y = p_data.location.y,
#			z = p_data.location.z
		},
		location_id = p_data.location_id,
		planet_id = p_data.planet_id
	}
	_execute_task(p_solar_system_id, p_planet_id, p_machine_id, p_requester_id, data)

func server_machine_mine(p_machine_id, task_id: String, p_data) -> void:
	client_machine_mine(p_machine_id, task_id, p_data)

func client_machine_mine(p_machine_id, task_id: String, p_data) -> void:
	task_requested.emit(p_machine_id, task_id, p_data)

func server_machine_move(miner_node_path, task_id: String, move_data: MoveMachineData):
	client_machine_move(miner_node_path, task_id, move_data)

func client_machine_move(machine_id: int, task_id: String, p_data: MoveMachineData):
	task_requested.emit(machine_id, task_id, p_data)



func machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	server_machine_collect_resource(machine_id, planet_id, location_id, _mine_speed)

func server_machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	client_machine_collect_resource(machine_id, planet_id, location_id, _mine_speed)

func client_machine_collect_resource(machine_id: NodePath, planet_id: int, location_id: int, _mine_speed: int = 10) -> void:
	var amount = _collect_resource(planet_id, location_id, _mine_speed)
	planet_resource_collected.emit(machine_id, planet_id, amount)

func cancel_task(solar_system_id: int, planet_id: int, machine_id: int, task_id: int, requester_id: String) -> void:
	_request.cancel_task(solar_system_id, planet_id, machine_id, task_id, requester_id)

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


func machine_move(p_solar_system_id, p_planet_id, p_machine_id: int, p_requester_id, task_name: String, move_data: MoveMachineData):
	var data := {
		task_name = task_name,
		from = {
			x = move_data.from.x,
			y = move_data.from.y
		},
		to = {
			x = move_data.to.x,
			y = move_data.to.y
		},
		speed = move_data.machine_speed,
		planet_radius = move_data.planet_radius
	}
	_execute_task(p_solar_system_id, p_planet_id, p_machine_id, p_requester_id, data)

func finish_task(p_solar_system_id: int, planet_id: int, p_machine_id:  int, task_id: int, requester_id: String):
	_request.finish_task(p_solar_system_id, planet_id, p_machine_id, task_id, requester_id)

func _execute_task(p_solar_system_id: int, planet_id: int, p_machine_id:  int, requester_id: String, task_data: Dictionary):
	_request.execute_task(p_solar_system_id, planet_id, p_machine_id, requester_id, task_data)


func join(p_username):
	_request.join(p_username)

func get_solar_system_data():
	_request.get_solar_system()

func get_planet_status(user_id, p_solar_system_id, p_planet_id) -> void:
	_request.get_planet_status(user_id, p_solar_system_id, p_planet_id)
