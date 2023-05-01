extends Control


func _on_login_pressed():
	Server.login()


func _on_send_request_pressed():
	Server.send_request()
