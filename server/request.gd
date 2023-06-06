extends Node

@onready var _http: HTTPRequest = get_parent().get_node("HTTPRequest")
var _queue: Array = []
var _is_requesting: bool = false

class Data:
	var url : String
	var headers: Array[String]
	var method_type
	var data: String

func join(p_username: String):
	var d := {
		username = p_username
	}
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/join"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func get_solar_system():
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/global_settings"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_GET
	data.data = ""
	_make_request(data)

func spawn_machine(solar_system_id, planet_id, requester_id: String, machine_asset_id: int):
	var d := {
		solar_system_id = solar_system_id,
		owner_id = requester_id,
		machine_id = machine_asset_id,
		planet_id = planet_id
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/spawn_machine"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func move_machine(p_solar_system_id, p_planet_id, p_requester_id, p_machine_id: int, task_id: String, task_data: MoveMachineData):
	var from := task_data.from
	var to := task_data.to
	var d := {
		requester_id = p_requester_id,
		task_id = task_id,
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_data = {
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
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/move_machine"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func cancel_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_task_id: int, p_username: String) -> void:
	var d := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_id = p_task_id,
		requester_id = p_username
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/cancel_task"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)


func get_planet_status(p_solar_system_id: int, p_planet_id: int, user_id: String):
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/get_planet_status/{0}/{1}/{2}".format([p_solar_system_id, p_planet_id, user_id])
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_GET
	data.data = ""
	_make_request(data)

func execute_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_requester_id: String, p_task_data: Dictionary):
	var d := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		requester_id = p_requester_id,
		task_data = p_task_data
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/execute_task"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func machine_mine(p_machine_id: NodePath, task_id: String, p_data) -> void:
	var d := {
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
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/mine_task"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func collect_resource(p_solar_system_id: int, p_planet_id: int, p_location_id: int, p_machine_id: int, p_requester_id: String) -> void:
	var d := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		requester_id = p_requester_id,
		location_id = p_location_id
#		task_data = p_task_data
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/mine_planet"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func finish_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_task_id: int, p_username: String) -> void:
	var d := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_id = p_task_id,
		requester_id = p_username
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/finish_task"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func get_machine_assets(p_requester: String):
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/get_inventory/{0}".format([p_requester])
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_GET
	data.data = ""
	_make_request(data)


func despawn_machine(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_requester_id: String) -> void:
	var d := {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
#		task_id = p_task_id,
		requester_id = p_requester_id
	}
	
	var data := Data.new()
	data.url = "http://127.0.0.1:5000/despawn_machine"
	data.headers = ["Content-Type: application/json"]
	data.method_type = HTTPClient.METHOD_POST
	data.data = JSON.stringify(d)
	_make_request(data)

func _make_request(p_data: Data):
	_queue.push_back(p_data)

func _send_request(p_data: Data):
	_http.request(p_data.url, p_data.headers, p_data.method_type, p_data.data)
	_is_requesting = true

func _on_http_request_request_completed(result, response_code, headers, body: PackedByteArray):
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
			Server.update_planet_deposits(data.solar_system_id, data.planet_id, data.planet_status.mine_points)
			Server.planet_status_requested.emit(data.solar_system_id, data.planet_id, data.planet_status)
		elif data.has("execute_task"):
			data = data.execute_task
			Server.execute_task_requested.emit(data.solar_system_id, data.planet_id, data.machine_id, data.requester_id, data.task_data)
		elif data.has("inventory_updated"):
			data = data.inventory_updated
			Server.inventory_updated.emit(data)
		elif data.has("mining"):
			Server.update_mining(data.solar_system_id, data.planet_id, data.mine_points)
		elif data.has("mine_planet"):
			data = data.mine_planet
#			print("Returning mining action")
			Server.set_mine_point_amount(data.solar_system_id, data.planet_id, data.location_id, data.remaining_amount)
		elif data.has("despawn_machine"):
			data = data.despawn_machine
			Server.despawn_machine_requested.emit(data.solar_system_id, data.planet_id, data.machine_id)
	
	_is_requesting = false

func _process(delta):
	if not _is_requesting and _queue.size() != 0:
		var d = _queue[0]
		_queue.pop_front()
		_send_request(d)
