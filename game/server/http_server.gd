class_name HTTPServer

signal resquest_finished(data)

var _client: HTTPClient = HTTPClient.new()
var _is_requesting: bool = false
var _is_connecting: bool = false
var _response: PackedByteArray

func login(username: String, password: String) -> void:
	_client.connect_to_host("127.0.0.1", 6969)
	_is_connecting = true

func logout() -> void:
	_client.close()

func make_request(p_method: int, p_url, p_headers: PackedStringArray, p_data: Dictionary) -> void:
	if _client.request_raw(p_method, p_url, p_headers, JSON.stringify(p_data).to_utf8_buffer()) != OK:
		push_error("Error making request")
		return
	_is_requesting = true
	_response = PackedByteArray()

func update():
	if _is_connecting:
		if _client.get_status() == HTTPClient.STATUS_CONNECTING or _client.get_status() == HTTPClient.STATUS_RESOLVING:
			_client.poll()
		else:
			assert(_client.get_status() == HTTPClient.STATUS_CONNECTED)
			_is_connecting = false
	elif _is_requesting:
		_client.poll()
#		if _client.get_status() == HTTPClient.STATUS_REQUESTING:
		
#		if _client.has_response():
#			print("has response")
		print(_client.get_status())
		if _client.get_status() == HTTPClient.STATUS_BODY:
#			print("body")
#				_client.poll()
			var chunk := _client.read_response_body_chunk()
			if chunk.size() != 0:
				_response += chunk
			else:
				_is_requesting = false;
				print(_response.get_string_from_utf8())
			
		
	

func is_http_connected():
	return _client.get_status() == HTTPClient.STATUS_CONNECTED

func _can_poll() -> bool:
	var status := _client.get_status()
	return (status == HTTPClient.STATUS_CONNECTED) || \
		(status == HTTPClient.STATUS_CONNECTING) || \
		(status == HTTPClient.STATUS_BODY) || \
		(status == HTTPClient.STATUS_REQUESTING) || \
		(status == HTTPClient.STATUS_RESOLVING)
