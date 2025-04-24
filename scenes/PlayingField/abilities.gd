extends HBoxContainer


signal abilityUsed(id: String)

# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	%AbilityPreRountIcon.texture = load("res://assets/abilities/" + Player.abilities.preRoundAbilityId + ".png")
	%AbilityEndRoundIcon.texture = load("res://assets/abilities/" + Player.abilities.endRoundAbilityId + ".png")
	%Ability1Icon.texture = load("res://assets/abilities/" + Player.abilities.ability1Id + ".png")
	%Ability2Icon.texture = load("res://assets/abilities/" + Player.abilities.ability2Id + ".png")
	%AbilityMainIcon.texture = load("res://assets/abilities/" + Player.abilities.mainAbilityId + ".png")
	
	Player.abilityCharged.connect(_on_ability_charged)


# ========================================
# ========= Interface ====================
# ========================================
func onRoundReset() -> void:
	%AbilityPreRound.disabled = false
	%AbilityEndRound.disabled = true


func onRoundStart() -> void:
	%AbilityPreRound.disabled = true
	%AbilityEndRound.disabled = false


# ========================================
# ========= Signals ======================
# ========================================
func _on_pre_round_ability_pressed() -> void:
	if %AbilityPreRound.disabled == false:
		%AbilityPreRound.disabled = true
		abilityUsed.emit(Player.abilities["preRoundAbilityId"])


func _on_end_round_ability_pressed() -> void:
	if %AbilityEndRound.disabled == false:
		%AbilityEndRound.disabled = true
		abilityUsed.emit(Player.abilities["endRoundAbilityId"])


func _on_ability_1_pressed() -> void:
	if %Ability1.disabled == false:
		%Ability1.disabled = true
		abilityUsed.emit(Player.abilities["ability1Id"])
		Player.abilities["ability1Charge"] = 0
		%Ability1Charge.value = 100
		%Ability1ChargeContainer.show()


func _on_ability_2_pressed() -> void:
	if %Ability2.disabled == false:
		%Ability2.disabled = true
		abilityUsed.emit(Player.abilities["ability2Id"])


func _on_ability_main_pressed() -> void:
	if %AbilityMain.disabled == false:
		%AbilityMain.disabled = true
		abilityUsed.emit(Player.abilities["mainAbilityId"])


func _on_ability_charged(type: String) -> void:
	var id = type.to_lower()
	var charge = Player.abilities[id + "Charge"]
	var fullCharge = AbilityDefinitions.details[Player.abilities[id + "Id"]]["fullCharge"]
	if charge > fullCharge:
		get_node("%" + type + "ChargeContainer").hide()
		get_node("%" + type).disabled = false
	else:
		get_node("%" + type + "Charge").value = 100 * (fullCharge - charge) / fullCharge
