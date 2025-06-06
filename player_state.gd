extends Node


signal abilityCharged(type: String)
signal dataChanged(id: String, valueNow)


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
		"ballProgressGain": 0,
		
		"chargePerRound": 0,
		
		"clearRowsOnRestart": 0,
		"currencyRewardPerLevel": 0,
		
		"probDeathTime": 0,
		"probCurrency": 0,
		"probCurrencyEventually": 0,
		"probPremiumCurrency": 0,
		"probPremiumCurrencyEventually": 0,
		"probDamage": 0,
		"probCharge": 0,
	},
	"ballProgressValue": 0,
	"ballProgressTarget": 0,
	"isDrawing": false,
	"doNotStartOnDrag": true,
	"challangeLevel": 0,
	"heros": {
		"Warrior": ["BallHell", "GlassCannon", "DoubleDamage"],
		"Guardian": ["BallHell", "AntiGravity", "Shield"],
		"Ghost": ["BallHell", "Phantom", "Portal"],
	}
}

var levelingDetails = {
	"damage": {
		"max": INF,
		"start": 1.,
		"levelBonus": 0.1,
		"cost": [2, 5, 5]
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
		"start": 40.,
		"levelBonus": -0.5,
		"cost": [2, 5, 10]
	},
	"ballProgressGain": {
		"max": 30,
		"start": 90.,
		"levelBonus": 1.,
		"cost": [2, 5, 10]
	},
	
	"chargePerRound": {
		"max": 20,
		"start": 0.1,
		"levelBonus": 0.01,
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
		
	"probDeathTime": {
		"max": 20,
		"start": 0.1,
		"levelBonus": 0.005,
		"cost": [2, 5, 5]
	},
	"probCurrency": {
		"max": 40,
		"start": 0.1,
		"levelBonus": 0.0025,
		"cost": [2, 5, 10]
	},
	"probCurrencyEventually": {
		"max": 40,
		"start": 0.25,
		"levelBonus": 0.004,
		"cost": [2, 5, 10]
	},
	"probPremiumCurrency": {
		"max": 20,
		"start": 0.02,
		"levelBonus": 0.001,
		"cost": [5, 5, 10]
	},
	"probPremiumCurrencyEventually": {
		"max": 20,
		"start": 0.04,
		"levelBonus": 0.001,
		"cost": [5, 5, 10]
	},
	"probDamage": {
		"max": 20,
		"start": 0.2,
		"levelBonus": 0.005,
		"cost": [2, 0, 2]
	},
	"probCharge": {
		"max": 40,
		"start": 0.5,
		"levelBonus": 0.01,
		"cost": [1, 2, 2]
	},
}

var upgrades: Dictionary = {}
var temporaryUpgrades: Dictionary = {
	"damage": 0,
	"nBalls": 0,
	"deathTime": 0,
}
var abilityUpgrades: Dictionary = {}

var abilities = {
	"PreRoundAbility": {
		"id": "LaserPointer",
		"charge": INF
	},
	"EndRoundAbility": {
		"id": "SuddenStop",
		"charge": INF
	},
	"Ability1": {
		"id": "Portal",
		"charge": INF
	},
	"Ability2": {
		"id": "Shield",
		"charge": INF
	},
	"MainAbility": {
		"id": "BallHell",
		"charge": INF
	}
}

var abilityDetails: Dictionary = {
	"AntiGravity": {
		"timed": true,
		"fullCharge": 10.0
	},
	"BallHell": {
		"fullCharge": 4.999
	},
	"DoubleDamage": {
		"fullCharge": 1.999
	},
	"GlassCannon": {
		"timed": true,
		"fullCharge": 0.5,
	},
	"LaserPointer": {
		"fullCharge": 2.999
	},
	"Pass": {
		"fullCharge": 0.
	},
	"Phantom": {
		"fullCharge": 4.999
	},
	"Portal": {
		"fullCharge": 2.999
	},
	"Shield": {
		"fullCharge": 2.999
	},
	"SuddenStop": {
		"fullCharge": -INF
	},
}


func _ready() -> void:
	loadState()
	determineUpgrades()


func _process(delta: float) -> void:
	# Increase charge of abilities, which run on a timer
	for ability in abilities:
		if "timed" in abilityDetails[abilities[ability].id]:
			abilities[ability].charge += delta
			abilityCharged.emit(ability)


func storeGameState() -> void:
	GameState.state.abilities = abilities
	GameState.state.temporaryUpgrades = temporaryUpgrades
	GameState.state.playerState = {
		"ballProgressValue": state.ballProgressValue,
		"ballProgressTarget": state.ballProgressTarget
	}


func reset() -> void:
	for ability in temporaryUpgrades:
		temporaryUpgrades[ability] = 0
	
	state.ballProgressValue = 0.
	setBallProgressTarget()
	
	for ability in abilities:
		abilities[ability].charge = INF
		abilityCharged.emit(ability)
	abilityUpgrades = {}


func addCharge(charge: float = 1.) -> void:
	var nonFullAbilities = {}
	for _i in 5: # Fixed number of loops as 5 buckets can only redistribute 5 times
		# Determine which abilities needs to be charged
		for ability in abilities:
			if "timed" in abilityDetails[abilities[ability].id]: continue
			var missing = missingCharge(ability)
			if missing > 0.: nonFullAbilities[ability] = missing
		
		if nonFullAbilities.size() == 0:
			break # no abilities waiting
		
		var chargePerAbility = charge / nonFullAbilities.size()
		for ability in nonFullAbilities:
			abilities[ability].charge += min(nonFullAbilities[ability], chargePerAbility)
			charge -= min(nonFullAbilities[ability], chargePerAbility)
			abilityCharged.emit(ability)
			
		if charge <= 1e-7: break


func increaseBallProgress() -> void:
	state.ballProgressValue += getUpgrade("ballProgressGain")
	if state.ballProgressValue > state.ballProgressTarget:
		state.ballProgressValue -= state.ballProgressTarget
		temporaryUpgrades.nBalls += 1
		setBallProgressTarget()
		
		dataChanged.emit("nBalls", getUpgrade("nBalls"))
		dataChanged.emit("ballProgressTarget", state.ballProgressTarget)
	dataChanged.emit("ballProgressValue", state.ballProgressValue)


func setBallProgressTarget() -> void:
	state.ballProgressTarget = getUpgrade("ballProgressCost") + \
		(getUpgrade("nBalls") - 1) * getUpgrade("ballProgressPerLevelCost")


func missingCharge(type: String) -> float:
	return abilityDetails[abilities[type].id].fullCharge - abilities[type].charge


func determineUpgrades() -> void:
	for upgrade in levelingDetails:
		var level = state["upgrades"][upgrade]
		var start = levelingDetails[upgrade]["start"]
		var levelBonus = levelingDetails[upgrade]["levelBonus"]
		
		upgrades[upgrade] = start + level * levelBonus
	
	setBallProgressTarget()


func getUpgradeWithoutEffects(id: String):
	var value = upgrades[id]
	if id in temporaryUpgrades:
		value += temporaryUpgrades[id]
	return value


func getUpgrade(id: String):
	var value = getUpgradeWithoutEffects(id)
	for ability in abilityUpgrades:
		if id in abilityUpgrades[ability]:
			value += abilityUpgrades[ability][id]
	return value


func incrementTemporaryUpgrade(id: String, value) -> void:
	temporaryUpgrades[id] += value
	dataChanged.emit(id, getUpgrade(id))


func setAbilityUpgrade(ability: String, id: String, value) -> void:
	if not ability in Player.abilityUpgrades:
		Player.abilityUpgrades[ability] = {}
	Player.abilityUpgrades[ability][id] = value
	dataChanged.emit(id, getUpgrade(id))


func removeAbilityUpgrade(ability: String) -> void:
	var ids = []
	if ability in Player.abilityUpgrades:
		for id in Player.abilityUpgrades[ability]:
			ids.append(id)
		Player.abilityUpgrades.erase(ability)
	for id in ids:
		dataChanged.emit(id, getUpgrade(id))


func onRoundReset() -> void:
	# Fully charge timer abilitites
	for ability in abilities:
		if "timed" in abilityDetails[abilities[ability].id]:
			abilities[ability].charge += missingCharge(ability)
			abilityCharged.emit(ability)


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
		if "highscore" in data: state["highscore"] = data["highscore"]
		if "currency" in data: state["currency"] = data["currency"]
		for upgradeName in data["upgrades"]:
			state["upgrades"][upgradeName] = data["upgrades"][upgradeName]
		file.close()
		
		
