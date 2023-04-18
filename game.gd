class_name Game
extends Node3D

@onready var _solar_system: SolarSystem = $SolarSystem

var _machine_selected: MachineCharacter = null

func get_solar_system() -> SolarSystem:
	return _solar_system

func _on_waypoint_hud_waypoint_selected(waypoint: Waypoint):
	var so = waypoint.get_selected_object()
	if so is MachineCharacter and not _machine_selected:
		_machine_selected = so
	if so is StellarBodyWrapper and _machine_selected:
		var data := MoveMachineData.new()
		data.from = _machine_selected.position
		data.to = waypoint.position
		data.machine_speed = _machine_selected.get_max_speed()
		data.planet_radius = _solar_system.get_reference_stellar_body().radius
		Server.move_machine(_machine_selected.get_path(), data)
		_machine_selected = null
