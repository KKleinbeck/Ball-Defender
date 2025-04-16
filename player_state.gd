extends Node


const playerDataLocation = "user://PlayerData.json"

var state = {
	"currency": {
		"standard": 0,
		"premium": 0
	},
	"upgrades": {
		"damage": 0,
		"deathTime": 0,
		
		"ballProgressCost": 0,
		"ballProgressPerLevelCost": 0,
		"ballProgressFlankAngle": 0,
		
		"pDeathTime": 0,
		"pCurrency": 0,
		"pCurrencyEventually": 0,
		"pPremiumCurrency": 0,
		"pPremiumCurrencyEventually": 0,
		"pCharge": 0
	},
	"challangeLevel": 0,
}

var levelingDetails = {
	"damage": {
		"max": INF,
		"cost": [2, 5, 10]
	},
	"deathTime": {
		"max": INF,
		"cost": [5, 5, 10]
	},
		
	"ballProgressCost": {
		"max": 50,
		"cost": [5, 5, 10]
	},
	"ballProgressPerLevelCost": {
		"max": 50,
		"cost": [2, 5, 10]
	},
	"ballProgressFlankAngle": {
		"max": 20,
		"cost": [2, 5, 10]
	},
		
	"pDeathTime": {
		"max": 20,
		"cost": [2, 5, 5]
	},
	"pCurrency": {
		"max": 30,
		"cost": [2, 5, 10]
	},
	"pCurrencyEventually": {
		"max": 30,
		"cost": [2, 5, 10]
	},
	"pPremiumCurrency": {
		"max": 30,
		"cost": [5, 5, 10]
	},
	"pPremiumCurrencyEventually": {
		"max": 30,
		"cost": [5, 5, 10]
	},
	"pCharge": {
		"max": INF,
		"cost": [2, 5, 10]
	},
}


func _ready() -> void:
	loadState()


func saveState() -> void:
	var file = FileAccess.open_encrypted_with_pass(playerDataLocation, FileAccess.WRITE, "yFOghex4gzvfW99uMON9rIzhc5rnXdj3")
	file.store_var(state.duplicate())
	file.close()


func loadState() -> void:
	if FileAccess.file_exists(playerDataLocation):
		var file = FileAccess.open_encrypted_with_pass(playerDataLocation, FileAccess.READ, "yFOghex4gzvfW99uMON9rIzhc5rnXdj3")
		var data = file.get_var()
		state["currency"] = data["currency"]
		for upgradeName in data["upgrades"]:
			state["upgrades"][upgradeName] = data["upgrades"][upgradeName]
		file.close()
		
		
