extends Node

const API_URL: String = "http://127.0.0.1:5000"

var _queue: Array = []
var _is_requesting: bool = false
var _request_processor: Dictionary = {}

@onready var _http: HTTPRequest = get_parent().get_node("HTTPRequest")

class Data extends RefCounted:
	var url : String
	var headers: PackedStringArray
	var method_type
	var data: String
	
	func make_request(u: String, m: int, d: Dictionary = {}, h: PackedStringArray = ["Content-Type: application/json"]) -> void:
		url = u
		headers = h
		method_type = m
		data = JSON.stringify(d) if not d.is_empty() else ""

func _ready() -> void:
	_register_processor_request()

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
	var data: Data = Data.new()
	data.make_request(API_URL + "/global_settings", HTTPClient.METHOD_GET)
	_make_request(data)

func spawn_machine(solar_system_id, planet_id, requester_id: String, machine_asset_id: int):
	var d: Dictionary = {
		solar_system_id = solar_system_id,
		owner_id = requester_id,
		machine_id = machine_asset_id,
		planet_id = planet_id
	}
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/spawn_machine", HTTPClient.METHOD_POST, d)
	_make_request(data)

func move_machine(p_solar_system_id, p_planet_id, p_requester_id, p_machine_id: int, task_id: String, task_data: MoveMachineData):
	var from: = task_data.from
	var to: = task_data.to
	var d: Dictionary = {
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
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/move_machine", HTTPClient.METHOD_POST, d)
	_make_request(data)

func cancel_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_task_id: int, p_username: String) -> void:
	var d: Dictionary = {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		task_id = p_task_id,
		requester_id = p_username
	}
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/cancel_task", HTTPClient.METHOD_POST, d)
	_make_request(data)


func get_planet_status(p_solar_system_id: int, p_planet_id: int, user_id: String):
	var data := Data.new()
	data.make_request(API_URL + "/get_planet_status/%s/%s/%s" % [p_solar_system_id, p_planet_id, user_id], HTTPClient.METHOD_GET)
	_make_request(data)


func get_planet_list(p_solar_system_id):
	var data := Data.new()
	data.make_request(API_URL + "/planet_list/%s" % [p_solar_system_id], HTTPClient.METHOD_GET)
	_make_request(data)

func execute_task(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_requester_id: String, p_task_data: Dictionary):
	var d: Dictionary = {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
		requester_id = p_requester_id,
		task_data = p_task_data
	}
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/execute_task", HTTPClient.METHOD_POST, d)
	_make_request(data)

func machine_mine(p_machine_id: NodePath, task_id: String, p_data) -> void:
	var d: Dictionary = {
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
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/mine_task", HTTPClient.METHOD_POST, d)
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
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/mine_planet", HTTPClient.METHOD_POST, d)
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
	data.make_request(API_URL + "/finish_task", HTTPClient.METHOD_POST, d)
	_make_request(data)

func get_machine_assets(p_requester: String):
	var data: Data = Data.new()
	data.make_request(API_URL + "/get_inventory/%s" % [p_requester], HTTPClient.METHOD_GET)
	_make_request(data)


func despawn_machine(p_solar_system_id: int, p_planet_id: int, p_machine_id: int, p_requester_id: String) -> void:
	var d: Dictionary = {
		solar_system_id = p_solar_system_id,
		planet_id = p_planet_id,
		machine_id = p_machine_id,
#		task_id = p_task_id,
		requester_id = p_requester_id
	}
	
	var data: Data = Data.new()
	data.make_request(API_URL + "/despawn_machine", HTTPClient.METHOD_POST, d)
	_make_request(data)

func collect_item(p_user_id: String, p_item_id: String, p_item_type: int, p_item_amount: int):
	var d := {
		user_id = p_user_id,
		item_id = p_item_id,
		item_type = p_item_type,
		item_amount = p_item_amount
	}
	
	var data := Data.new()
	data.make_request(API_URL + "/collect_item", HTTPClient.METHOD_POST, d)
	_make_request(data)

func _make_request(p_data: Data):
	_queue.push_back(p_data)

func _send_request(p_data: Data):
	_http.request(p_data.url, p_data.headers, p_data.method_type, p_data.data)
	_is_requesting = true


func _register_processor_request() -> void:
	_request_processor["planet_data"] = func (data: Dictionary) -> void:
		Server.solar_system_requested.emit(data.planet_data)
	
	_request_processor["login"] = func (data: Dictionary) -> void:
		Server.login_requested.emit(data)
	
	_request_processor["spawn_machine"] = func (data: Dictionary) -> void:
		data = data.spawn_machine
		Server.client_miner_spawn(data.owner_id, data.planet_id, data.machine_asset_id, data.machine_instance_id, data)
	
	_request_processor["cancel_task"] = func (data: Dictionary) -> void:
		data = data.cancel_task
		if data.is_empty():
			push_error("Failed to cancel task")
		else:
			Server.task_cancelled.emit(data.solar_system_id, data.planet_id, data.machine_id, data.task_id, data.requester_id)
	
	_request_processor["planet_status"] = func (data: Dictionary) -> void:
		Server.update_planet_deposits(data.solar_system_id, data.planet_id, data.planet_status.mine_points)
		Server.planet_status_requested.emit(data.solar_system_id, data.planet_id, data.planet_status)
	
	_request_processor["execute_task"] = func (data: Dictionary) -> void:
		data = data.execute_task
		Server.execute_task_requested.emit(data.solar_system_id, data.planet_id, data.machine_id, data.requester_id, data.task_data)
	
	_request_processor["inventory_update"] = func (data: Dictionary) -> void:
		data = data.inventory_updated
		Server.inventory_updated.emit(data)
	
	_request_processor["inventory_update"] = func (data: Dictionary) -> void:
		data = data.inventory_updated
		Server.inventory_updated.emit(data)
	
	_request_processor["mining"] = func (data: Dictionary) -> void:
		Server.update_mining(data.solar_system_id, data.planet_id, data.mine_points)
	
	_request_processor["minine_planet"] = func (data: Dictionary) -> void:
		data = data.mine_planet
		Server.set_mine_point_amount(data.solar_system_id, data.planet_id, data.location_id, data.remaining_amount)
	
	_request_processor["despawn_machine"] = func (data: Dictionary) -> void:
		data = data.despawn_machine
		Server.despawn_machine_requested.emit(data.solar_system_id, data.planet_id, data.machine_id)
	
	_request_processor["collect_item"] = func (data: Dictionary) -> void:
		data = data.collect_item
		Server.resource_collected.emit(data.item_id, data.item_amount)
	
	_request_processor["planet_list"] = func (data: Dictionary) -> void:
		data = data.planet_list
		Server.planet_listed.emit(data.solar_system_id, data.planet_ids)


func _on_http_request_request_completed(result, response_code, headers, body: PackedByteArray) -> void:
	if response_code == 200:
		var data: Dictionary = JSON.parse_string(body.get_string_from_utf8())
		for r in _request_processor.keys():
			if data.has(r):
				_request_processor[r].call(data)
				break
	_is_requesting = false

func _process(delta):
	if not _is_requesting and _queue.size() != 0:
		var d = _queue[0]
		_queue.pop_front()
		_send_request(d)
