extends Node


func _on_button_pressed():
	Server.join("User Jordan: " + str(randi()))
