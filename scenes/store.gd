extends Control


var optionDict: Dictionary = {}


func _ready() -> void:
	displayCurrency()
	
	var optionScene = load("res://scenes/Store/UpgradeOption.tscn")
	for upgradeName in Player.state["upgrades"]:
		var optionInstance = optionScene.instantiate()
		optionInstance.identifier = upgradeName
		optionInstance.setAbility(tr("UPGRADE_" + upgradeName.to_upper()))
		
		var level = Player.state.upgrades[upgradeName]
		var maxLevel = Player.levelingDetails[upgradeName].max
		optionInstance.setLevel(level, maxLevel)
		
		var upgradeCost = cost(upgradeName, level)
		optionInstance.setCost(upgradeCost)
		
		var currentEffect = LocalisationHelper.upgradeEffect(upgradeName, level)
		var newEffect = LocalisationHelper.upgradeEffect(upgradeName, level + 1)
		optionInstance.setEffect(currentEffect, newEffect)
		
		optionDict[upgradeName] = optionInstance
		optionInstance.upgrade.connect(_on_upgrade)
		optionInstance.size_flags_horizontal = SIZE_EXPAND_FILL
		$GridContainer.add_child(optionInstance)


func cost(identifier: String, level: int) -> int:
	var polynomCoefs = Player.levelingDetails[identifier]["cost"]
	return 5 * int(( (polynomCoefs[0] * level + polynomCoefs[1]) * level + polynomCoefs[2] ) / 5 )


func displayCurrency() -> void:
	%Standard.text = str(Player.state.currency.standard)
	%Premium.text = str(Player.state.currency.premium)


func redraw(identifier: String) -> void:
	var optionInstance = optionDict[identifier]
	
	var level = Player.state.upgrades[identifier]
	var maxLevel = Player.levelingDetails[identifier].max
	optionInstance.setLevel(level, maxLevel)
	var upgradeCost = cost(identifier, level)
	optionInstance.setCost(upgradeCost)
	var currentEffect = LocalisationHelper.upgradeEffect(identifier, level)
	var newEffect = LocalisationHelper.upgradeEffect(identifier, level + 1)
	optionInstance.setEffect(currentEffect, newEffect)
	
	displayCurrency()


func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_upgrade(identifier) -> void:
	var level = Player.state["upgrades"][identifier]
	var upgradeCost = cost(identifier, level)
	if upgradeCost <= Player.state["currency"]["standard"]:
		Player.state["currency"]["standard"] -= upgradeCost
		Player.state["upgrades"][identifier] += 1
		Player.determineUpgrades()
		redraw(identifier)
		Player.saveState()
