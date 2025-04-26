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
	
	Player.abilityCharged.connect(_on_ability_charged)


# ========================================
# ========= Interface ====================
# ========================================
func onRoundReset() -> void:
	%PreRoundAbility.disabled = false
	if Player.missingCharge("EndRoundAbility") < 0:
		%EndRoundAbility.disabled = true


func onRoundStart() -> void:
	if Player.missingCharge("PreRoundAbility") < 0:
		%PreRoundAbility.disabled = true
	%EndRoundAbility.disabled = false


func onAbilityPressed(type: String) -> void:
	var ability = get_node("%" + type)
	if ability.disabled == false:
		ability.disabled = true
		abilityUsed.emit(Player.abilities[type]["id"])
		Player.abilities[type]["charge"] = 0.
		get_node("%" + type + "Charge").value = 100
		get_node("%" + type + "ChargeContainer").show()


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
	if charge > fullCharge:
		get_node("%" + type + "ChargeContainer").hide()
		get_node("%" + type).disabled = false
	else:
		get_node("%" + type + "Charge").value = 100 * (fullCharge - charge) / fullCharge
