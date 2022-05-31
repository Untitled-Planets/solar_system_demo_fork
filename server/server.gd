extends Node

var inventory = {}
var planets = {
	
	"dummy": {
		
		"deposits": [
		
			{
				"pos": Vector2(0, 0),
				"amount": 100,
			},

			{
				"pos": Vector2(90, 90),
				"amount": 100,
			},
			
			{
				"pos": Vector2(90, -90),
				"amount": 100,
			},
		]
	}
}

var planet_id = "dummy"

func _call_event(name, params):
	get_tree().call_group(name, params)

func planet_travel(planet_id):
	_call_event("server_planet_traveled", planet_id)

func planet_info_refresh():
	_call_event("server_planet_info_refreshed", 0)

func planet_get_deposits():
	return planets[planet_id].deposits
	
func planet_get_deposit_info(pos):
	return planets[planet_id].deposits[pos]

func inventory_refresh():
	_call_event("server_inventory_refreshed", 0)

func miner_get_status(miner_id):
	return inventory.miners[miner_id]

func miner_spawn(miner_id, planet_id):
	_call_event("server_miner_spawn", [OK, miner_id, planet_id])
	return OK

func miner_attach(miner_id, planet_id, pos):
	_call_event("server_miner_attach", [OK, miner_id, planet_id, pos])
	return OK

func sign_in():
	_call_event("server_signed_in", 0)

func _ready():
	pass # Replace with function body.

