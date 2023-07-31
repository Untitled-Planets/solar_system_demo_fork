class_name Station
extends Node3D


var character_spawn_position: Vector3:
	get:
		return $char_pivot.global_position

var spaceship_spawn_position: Vector3:
	get:
		return $spacehsip_pivot.global_position
