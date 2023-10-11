extends MultiplayerServerAPI
class_name MultiplayerServerWebSocket

var _socket: WebSocketPeer = WebSocketPeer.new()

func connect_to_server(url: String) -> Error:
	var err: Error = _socket.connect_to_url(url)
	
	if err == OK:
		set_process(true)
	
	return err

func close() -> void:
	_socket.close()

func send_data(type: MessageType, data: Dictionary):
	print("Sending data")
	var utf: String = JSON.stringify({"type": type, "data": data})
	var packet: PackedByteArray = utf.to_utf8_buffer()
	var err: int = _socket.send_text(utf)
	
	if err != OK:
		printerr("Error sending the packet type %s - ERROR_CODE: %s" % [type, error_string(err)])


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	if _socket == null:
		return
	
	_socket.poll()
	
	var state: WebSocketPeer.State = _socket.get_ready_state()
	
	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var packet: PackedByteArray = _socket.get_packet()
			var err: Error = _socket.get_packet_error()
			
			if err == OK:
				var utf: String = packet.get_string_from_utf8()
				var data: Dictionary = JSON.parse_string(utf)
				
				if data.get('type') != null and data.get('data') != null:
					var messageType: MessageType = data.get('type')
					var dataDic: Dictionary = data.get('data', {})
					packet_recived.emit(messageType, dataDic)
					
					match messageType:
						MessageType.CLIENT_CONNECTED:
							var peer: int = dataDic.get("peer")
							var id: String = dataDic.get("id")
							_client_connected(id, peer, dataDic)
						MessageType.SYNC_DATA:
							OS.alert("Sync data recived")
							_server_connected(dataDic.get("playerId"), dataDic.get("peerId"), dataDic.get("playersList"), dataDic.get("shipsList"))
	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _socket.get_close_code()
		var reason: String = _socket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false)


func start_collect_resource() -> void:
	var type: MessageType = MessageType.COLLECT_RESOURCE_START
	send_data(type, {})


func start_refin_resource() -> void:
	var type: MessageType = MessageType.REFIN_RESOURCE_START
	send_data(type, {})

