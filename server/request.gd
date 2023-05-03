extends Node

@onready var _http: HTTPRequest = get_parent().get_node("HTTPRequest")

func join(p_username: String):
	var d := {
		username = p_username
	}
	_http.request("http://127.0.0.1:5000/join", ["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(d))


func _on_http_request_request_completed(result, response_code, headers, body: PackedByteArray):
#	print(response_code)
	if response_code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		Server.login_requested.emit(data)
