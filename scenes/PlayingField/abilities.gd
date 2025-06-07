extends HBoxContainer


signal abilityUsed(id: String)

# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	%PreRoundAbilityIcon.texture = load("res://assets/abilities/" + Player.abilities.PreRoundAbility.id + ".png")
	%EndRoundAbilityIcon.texture = load("res://assets/abilities/" + Player.abilities.EndRoundAbility.id + ".png")
	%Ability1Icon.texture = load("res://assets/abilities/" + Player.abilities.Ability1.id + ".png")
	%Ability2Icon.texture = load("res://assets/abilities/" + Player.abilities.Ability2.id + ".png")
	%MainAbilityIcon.texture = load("res://assets/abilities/" + Player.abilities.MainAbility.id + ".png")
	
	if GameState.runningReloadedGame:
		for key in GameState.state.abilities:
			var ability = GameState.state.abilities[key]
			var fullCharge = Player.abilityDetails[ability.id]["fullCharge"]
			if ability.charge < fullCharge:
				get_node("%" + key).disabled = true
				get_node("%" + key + "Charge").value = 100 * (fullCharge - ability.charge) / fullCharge
	
	Player.abilityCharged.connect(_on_ability_charged)


# ========================================
# ========= Interface ====================
# ========================================
func onRoundReset() -> void:
	if Player.missingCharge("PreRoundAbility") < 0:
		%PreRoundAbility.disabled = false
	%EndRoundAbility.disabled = true


func onRoundStart() -> void:
	%PreRoundAbility.disabled = true
	if Player.missingCharge("EndRoundAbility") < 0:
		%EndRoundAbility.disabled = false


func onAbilityPressed(type: String) -> void:
	var ability = get_node("%" + type)
	if ability.disabled == false:
		var abilityName = Player.abilities[type]["id"]
		if AbilityDefinitions.factory[abilityName].active: return
		
		ability.disabled = true
		abilityUsed.emit(abilityName)
		Player.abilities[type]["charge"] = 0.
		get_node("%" + type + "Charge").value = 100


# ========================================
# ========= Signals ======================
# ========================================
func _on_pre_round_ability_pressed() -> void:
	onAbilityPressed("PreRoundAbility")


func _on_end_round_ability_pressed() -> void:
	onAbilityPressed("EndRoundAbility")


func _on_ability_1_pressed() -> void:
	onAbilityPressed("Ability1")


func _on_ability_2_pressed() -> void:
	onAbilityPressed("Ability2")


func _on_ability_main_pressed() -> void:
	onAbilityPressed("MainAbility")


func _on_ability_charged(type: String) -> void:
	var charge = Player.abilities[type].charge
	var fullCharge = Player.abilityDetails[Player.abilities[type].id]["fullCharge"]
	if charge < fullCharge:
		get_node("%" + type + "Charge").value = 100 * (fullCharge - charge) / fullCharge
	else: # and charge > fullCharge
		get_node("%" + type + "Charge").value = 100
		if type != "PreRoundAbility":
			get_node("%" + type).disabled = false
