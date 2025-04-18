extends Node


const playerDataLocation = "user://PlayerData.json"

var state = {
	"highscore": 0,
	"currency": {
		"standard": 0,
		"premium": 0
	},
	"upgrades": {
		"damage": 0,
		"deathTime": 0,
		
		"nBalls": 0,
		"ballProgressCost": 0,
		"ballProgressPerLevelCost": 0,
		"ballProgressFlankAngle": 0,
		
		"clearRowsOnRestart": 0,
		"currencyRewardPerLevel": 0,
		
		"pDeathTime": 0,
		"pCurrency": 0,
		"pCurrencyEventually": 0,
		"pPremiumCurrency": 0,
		"pPremiumCurrencyEventually": 0,
		"pDamage": 0,
		"pCharge": 0,
	},
	"challangeLevel": 0,
}

var levelingDetails = {
	"damage": {
		"max": INF,
		"start": 1.,
		"levelBonus": 0.1,
		"cost": [2, 5, 10]
	},
	"deathTime": {
		"max": 25,
		"start": 5,
		"levelBonus": 1,
		"cost": [5, 5, 10]
	},
		
	"nBalls": {
		"max": 9,
		"start": 1,
		"levelBonus": 1,
		"cost": [10, 40, 50]
	},
	"ballProgressCost": {
		"max": 50,
		"start": 360,
		"levelBonus": -3.5,
		"cost": [5, 5, 10]
	},
	"ballProgressPerLevelCost": {
		"max": 20,
		"start": 20.,
		"levelBonus": -0.5,
		"cost": [2, 5, 10]
	},
	"ballProgressFlankAngle": {
		"max": 30,
		"start": 0.,
		"levelBonus": 1.,
		"cost": [2, 5, 10]
	},
	
	"clearRowsOnRestart": {
		"max": 5,
		"start": 3,
		"levelBonus": 1,
		"cost": [10, 40, 50]
	},
	"currencyRewardPerLevel": {
		"max": 40,
		"start": 0.2,
		"levelBonus": 0.02,
		"cost": [10, 0, 10]
	},
		
	"pDeathTime": {
		"max": 20,
		"start": 0.1,
		"levelBonus": 0.005,
		"cost": [2, 5, 5]
	},
	"pCurrency": {
		"max": 40,
		"start": 0.1,
		"levelBonus": 0.0025,
		"cost": [2, 5, 10]
	},
	"pCurrencyEventually": {
		"max": 40,
		"start": 0.25,
		"levelBonus": 0.004,
		"cost": [2, 5, 10]
	},
	"pPremiumCurrency": {
		"max": 20,
		"start": 0.02,
		"levelBonus": 0.001,
		"cost": [5, 5, 10]
	},
	"pPremiumCurrencyEventually": {
		"max": 20,
		"start": 0.04,
		"levelBonus": 0.001,
		"cost": [5, 5, 10]
	},
	"pDamage": {
		"max": 50,
		"start": 0.5,
		"levelBonus": 0.002,
		"cost": [2, 5, 10]
	},
	"pCharge": {
		"max": 5,
		"start": 0.5,
		"levelBonus": 0.1,
		"cost": [2, 5, 10]
	},
}

var upgrades: Dictionary = {}
var temporaryUpgrades: Dictionary = {
	"damage": 0
}


func _ready() -> void:
	loadState()
	determineUpgrades()


func determineUpgrades() -> void:
	for upgrade in levelingDetails:
		var level = state["upgrades"][upgrade]
		var start = levelingDetails[upgrade]["start"]
		var levelBonus = levelingDetails[upgrade]["levelBonus"]
		
		upgrades[upgrade] = start + level * levelBonus


func endOfGameUpdates(highscore, currencyReward) -> void:
	Player.state["highscore"] = max(Player.state["highscore"], highscore)
	Player.state["currency"]["standard"] += currencyReward
	Player.saveState()


func saveState() -> void:
	var file = FileAccess.open_encrypted_with_pass(playerDataLocation, FileAccess.WRITE, "yFOghex4gzvfW99uMON9rIzhc5rnXdj3")
	file.store_var(state.duplicate())
	file.close()


func loadState() -> void:
	if FileAccess.file_exists(playerDataLocation):
		var file = FileAccess.open_encrypted_with_pass(playerDataLocation, FileAccess.READ, "yFOghex4gzvfW99uMON9rIzhc5rnXdj3")
		var data = file.get_var()
		state["highscore"] = data["highscore"]
		state["currency"] = data["currency"]
		for upgradeName in data["upgrades"]:
			state["upgrades"][upgradeName] = data["upgrades"][upgradeName]
		file.close()
		
		
