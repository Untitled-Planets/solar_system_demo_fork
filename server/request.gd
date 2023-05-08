extends Node

@onready var _http: HTTPRequest = get_parent().get_node("HTTPRequest")

func join(p_username: String):
	var d := {
		username = p_username
	}
	_http.request("http://127.0.0.1:5000/join", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(d))


func get_solar_system():
	_http.request("http://127.0.0.1:5000/global_settings", ["Content-Type: application/json"], HTTPClient.METHOD_GET)

func spawn_machine(controller_id, planet_id, miner_id):
	var data := {
		owner_id = controller_id,
		machine_id = miner_id,
		planet_id = planet_id
	}
	_http.request("http://127.0.0.1:5000/spawn_machine", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func move_machine(miner_node_path: NodePath, task_id: String, move_data: MoveMachineData):
	var from := move_data.from
	var to := move_data.to
	var data := {
		owner_id = 1,
		task_id = task_id,
		move_data = {
			machine_path = miner_node_path.get_concatenated_names(),
			from = {
				x = from.x,
				y = from.y,
				z = from.z
			},
			to = {
				x = to.x,
				y = to.y,
				z = to.z
			},
			planet_radius = move_data.planet_radius,
			machine_speed = move_data.machine_speed
		}
	}
	_http.request("http://127.0.0.1:5000/move_machine", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

func cancel_task(machine_path_id: NodePath, task_name: String) -> void:
	var data := {
		machine_path = machine_path_id.get_concatenated_names(),
		task_id = task_name
	}
	_http.request("http://127.0.0.1:5000/cancel_task", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(data))

#class MineTaskData:
#	var location: Vector2
#	var planet_id:  int
#	var location_id: int = -1
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

func _on_http_request_request_completed(result, response_code, headers, body: PackedByteArray):
#	print(response_code)
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data.has("planet_data"):
			Server.solar_system_requested.emit(data.planet_data)
		elif data.has("login"):
			Server.login_requested.emit(data)
		elif data.has("spawn_machine"):
#			func client_miner_spawn(controller_id, miner_id, planet_id, spawn_location) -> void:
			data = data.spawn_machine
			Server.client_miner_spawn(data.owner_id, data.planet_id, data.machine_asset_id, data.machine_instance_id)
		elif data.has("move_machine"):
			data = data.move_machine
#			var path = Server.get_tree().root.get_node(data.move_data.machine_path)
			var path = data.move_data.machine_path
			var md := MoveMachineData.new()
			md.from = Vector3(data.move_data.from.x, data.move_data.from.y, data.move_data.from.z)
			md.to = Vector3(data.move_data.to.x, data.move_data.to.y, data.move_data.to.z)
			md.machine_speed = data.move_data.machine_speed
			md.planet_radius = data.move_data.planet_radius
			Server.client_machine_move("/" + path, data.task_id, md)
		elif data.has("cancel_task"):
			data = data.cancel_task
			Server.client_cancel_task("/" + data.machine_path, data.task_id)
		elif data.has("mine_task"):
			data = data.mine_task
			var md := Miner.MineTaskData.new()
			md.location = Vector2(data.mine_data.location.x, data.mine_data.location.y)
			md.planet_id = data.mine_data.planet_id
			md.location_id = data.mine_data.location_id
			Server.client_machine_mine("/" + data.machine_id, data.task_id, md)
