extends MultiplayerServerAPI
class_name MultiplayerServerWebSocket

var _socket: WebSocketPeer = WebSocketPeer.new()
var _wait_auth: bool = true
var _wait_auth_response: bool = false

func connect_to_server(url: String, p_username: String) -> Error:
	_socket.inbound_buffer_size = 1 << 29
	var err: Error = _socket.connect_to_url(url)
	
	if err == OK:
		_wait_auth = true
		_username = p_username
		_wait_auth_response = false
		set_process(true)
	
	return err

func close() -> void:
	_socket.close()

func send_data(type: MessageType, data: Dictionary) -> Error:
	var utf: String = JSON.stringify({"type": type, "data": data})
	var err: Error = _socket.send_text(utf)
	
	if err != OK:
		printerr("Error sending the packet type %s - ERROR_CODE: %s" % [type, error_string(err)])
	return err


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	if _socket == null:
		return
	
	_socket.poll()
	
	var state: WebSocketPeer.State = _socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		if _wait_auth and not _wait_auth_response:
			_wait_auth_response = true
			print("sending auth request...")
			send_data(MessageType.AUTH_REQUEST, {
				"username": _username
			})
		else:
			if _socket.get_available_packet_count():
				while _socket.get_available_packet_count():
					_process_packet()
			else:
				pass
	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _socket.get_close_code()
		var reason: String = _socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		if code == -1:
			OS.alert("Error to connect with the server")
		
		set_process(false)


func _process_packet() -> void:
	var packet: PackedByteArray = _socket.get_packet()
	var err: Error = _socket.get_packet_error()
	
	if err == OK:
		var utf: String = packet.get_string_from_utf8()
		var data: Dictionary = JSON.parse_string(utf)
		
		if data.get('type') != null and data.get('data') != null:
			var messageType: MessageType = data.get('type')
			var dataDic: Dictionary = data.get('data', {})
			
			match messageType:
				MessageType.AUTH_FAIL:
					pass
				MessageType.CLIENT_CONNECTED:
					print("new client connected")
					var peer: int = dataDic.get("peer")
					var id: String = dataDic.get("id")
					_client_connected(id, peer, dataDic)
				MessageType.CLIENT_DISCONNECTED:
					print("client disconnected")
					var disconnected_id: String = dataDic.get("playerId")
					_client_disconnected(disconnected_id)
				MessageType.SYNC_DATA:
					_wait_auth = false
					_wait_auth_response = false
					var planet_data: Dictionary = dataDic["referenceBodyData"]
					var sync_pos: Vector3 = Vector3.ZERO
					var inv: MultiplayerServerAPI.Inventory = MultiplayerServerAPI.Inventory.new()
					
					
					if dataDic.has("playerPosition"):
						sync_pos = Util.deserialize_vec3(dataDic["playerPosition"])
					
					if dataDic.has("inventory"):
						for i in dataDic["inventory"]:
							print(i)
							var item: MultiplayerServerAPI.Item = MultiplayerServerAPI.Item.new(i["id"], i["name"], i["type"], i["stock"], i.get("description", ""))
							inv.push(item)
					
					
					_update_reference_body(planet_data["id"], dataDic["mineralManager"])
					print("connected to server")
					_server_connected(dataDic.get("playerId"), dataDic.get("peerId"), dataDic.get("playersList"), dataDic.get("shipsList"), sync_pos, inv)
				MessageType.PLANET_STATE:
					var planet_data: Dictionary = dataDic["referenceBodyData"]
					_update_reference_body(planet_data["id"], dataDic["mineralManager"])
				MessageType.CHAT:
					pass
				MessageType.SHIP_INTERACT_RESULT:
					waiting_entership_result = false
			
			packet_recived.emit(messageType, dataDic)
	else:
		OS.alert(error_string(err))


func start_collect_resource(resource_id: int) -> void:
	var type: MessageType = MessageType.COLLECT_RESOURCE_START
	send_data(type, {
		"mineralId": resource_id
		})


func start_refin_resource(amount: int) -> void:
	var type: MessageType = MessageType.REFIN_RESOURCE_START
	send_data(type, {
		"refCount": amount
	})


func enter_ship(ship_id: String) -> void:
	if not waiting_entership_result:
		send_data(MessageType.ENTER_SHIP, {
			"shipId": ship_id
		})
		waiting_entership_result = true


func exit_ship(spawn_position: Vector3) -> void:
	if not waiting_entership_result:
		send_data(MessageType.EXIT_SHIP, {
			"spawnPos": Util.serialize_vec3(spawn_position)
		})
		waiting_entership_result = true
