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


func _on_ability_2_pressed() -> void:
	if %Ability2.disabled == false:
		%Ability2.disabled = true
		abilityUsed.emit(Player.abilities["ability2Id"])


func _on_ability_main_pressed() -> void:
	if %AbilityMain.disabled == false:
		%AbilityMain.disabled = true
		abilityUsed.emit(Player.abilities["mainAbilityId"])
