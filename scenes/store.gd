extends Control


var optionDict: Dictionary = {}


func _ready() -> void:
	displayCurrency()
	
	var optionScene = load("res://scenes/Store/UpgradeOption.tscn")
	for upgradeName in Player.state["upgrades"]:
		var optionInstance = optionScene.instantiate()
		optionInstance.identifier = upgradeName
		optionInstance.setTitle(upgradeName)
		
		var level = Player.state["upgrades"][upgradeName]
		optionInstance.setLevel(level)
		
		var upgradeCost = cost(upgradeName, level)
		optionInstance.setCost(upgradeCost)
		
		optionDict[upgradeName] = optionInstance
		optionInstance.upgrade.connect(_on_upgrade)
		$VBoxContainer.add_child(optionInstance)


func cost(identifier: String, level: int) -> int:
	var polynomCoefs = Player.levelingDetails[identifier]["cost"]
	return 5 * int(( (polynomCoefs[0] * level + polynomCoefs[1]) * level + polynomCoefs[2] ) / 5 )


func displayCurrency() -> void:
	%Standard.text = str(Player.state["currency"]["standard"])
	%Premium.text = str(Player.state["currency"]["premium"])


func redraw(identifier: String) -> void:
	var optionInstance = optionDict[identifier]
	
	var level = Player.state["upgrades"][identifier]
	optionInstance.setLevel(level)
	var upgradeCost = cost(identifier, level)
	optionInstance.setCost(upgradeCost)
	
	displayCurrency()


func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_upgrade(identifier) -> void:
	var level = Player.state["upgrades"][identifier]
	var upgradeCost = cost(identifier, level)
	if upgradeCost <= Player.state["currency"]["standard"]:
		Player.state["currency"]["standard"] -= upgradeCost
		Player.state["upgrades"][identifier] += 1
	redraw(identifier)
	Player.saveState()
