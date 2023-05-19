extends Node

@onready var _http: HTTPRequest = get_parent().get_node("HTTPRequest")

func join(p_username: String):
	var d := {
		username = p_username
	}
	_http.request("http://127.0.0.1:5000/join", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(d))


func get_solar_system():
	_http.request("http://127.0.0.1:5000/global_settings", ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func spawn_machine(solar_system_id, planet_id, requester_id: String, machine_asset_id: int):
	var data := {
		solar_system_id = solar_system_id,
		owner_id = requester_id,
		machine_id = machine_asset_id,
		planet_id = planet_id
	}
	_http.request("http://127.0.0.1:5000/spawn_machine", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func move_machine(p_solar_system_id, p_planet_id, p_requester_id, p_machine_id: int, task_id: String, task_data: MoveMachineData):
	var from := task_data.from
	var to := task_data.to
	var data := {
		requester_id = p_requester_id,
		task_id = task_id,
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_data = {
#			machine_path = miner_node_path.get_concatenated_names(),
			from = {
				x = from.x,
				y = from.y
			},
			to = {
				x = to.x,
				y = to.y
			},
			planet_radius = task_data.planet_radius,
			machine_speed = task_data.machine_speed
		}
	}
	_http.request("http://127.0.0.1:5000/move_machine", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func cancel_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_task_id: int, p_username: String) -> void:
	var data := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_id = p_task_id,
		requester_id = p_username
	}
	_http.request("http://127.0.0.1:5000/cancel_task", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))


func get_planet_status(user_id, p_solar_system_id: int, p_planet_id: int):
	var url := "http://127.0.0.1:5000/get_planet_status/{0}/{1}".format([p_solar_system_id, p_planet_id])
	_http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_GET)
	pass

func execute_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_requester_id: String, p_task_data: Dictionary):
	var data := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		requester_id = p_requester_id,
		task_data = p_task_data
	}
	
	_http.request("http://127.0.0.1:5000/execute_task", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func machine_mine(p_machine_id: NodePath, task_id: String, p_data) -> void:
	var data := {
		machine_id = p_machine_id.get_concatenated_names(),
		task_id = task_id,
		mine_data = {
			location = {
				x = p_data.location.x,
				y = p_data.location.y
			},
			planet_id = p_data.planet_id,
			location_id = p_data.location_id
		}
	}
	
	_http.request("http://127.0.0.1:5000/mine_task", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func finish_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_task_id: int, p_username: String) -> void:
	var data := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_id = p_task_id,
		requester_id = p_username
	}
	_http.request("http://127.0.0.1:5000/finish_task", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func _on_http_request_request_completed(result, response_code, headers, body: PackedByteArray):
#	print(response_code)
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data.has("planet_data"):
			Server.solar_system_requested.emit(data.planet_data)
		elif data.has("login"):
			Server.login_requested.emit(data)
		elif data.has("spawn_machine"):
			data = data.spawn_machine
			Server.client_miner_spawn(data.owner_id, data.planet_id, data.machine_asset_id, data.machine_instance_id)
		elif data.has("cancel_task"):
			data = data.cancel_task
			if data.is_empty():
				push_error("Failed to cancel task")
			else:
				Server.task_cancelled.emit(data.solar_system_id, data.planet_id, data.machine_id, data.task_id, data.requester_id)
		elif data.has("planet_status"):
			Server.planet_status_requested.emit(data.solar_system_id, data.planet_id, data.planet_status)
			Server.update_planet_deposits(data.solar_system_id, data.planet_id, data.planet_status.mine_points)
		
		elif data.has("execute_task"):
			data = data.execute_task
			Server.execute_task_requested.emit(data.solar_system_id, data.planet_id, data.machine_id, data.requester_id, data.task_data)
