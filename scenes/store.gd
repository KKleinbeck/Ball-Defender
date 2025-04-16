extends Control


func _ready() -> void:
	%Standard.text = str(Player.state["currency"]["standard"])
	%Premium.text = str(Player.state["currency"]["premium"])
	
	var optionScene = load("res://scenes/Store/UpgradeOption.tscn")
	for upgradeName in Player.state["upgrades"]:
		var optionInstance = optionScene.instantiate()
		optionInstance.setTitle(upgradeName)
		
		var level = Player.state["upgrades"][upgradeName]
		optionInstance.setLevel(level)
		
		var polynomCoefs = Player.levelingDetails[upgradeName]["cost"]
		var cost = 5 * int(( (polynomCoefs[0] * level + polynomCoefs[1]) * level + polynomCoefs[2] ) / 5 )
		optionInstance.setCost(cost)
		
		$VBoxContainer.add_child(optionInstance)


func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
