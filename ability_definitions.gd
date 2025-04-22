extends Node


var ability1Active: bool = false
var ability1Store: Dictionary = {}


func startGlassCannon() -> void:
	ability1Active = false
	ability1Store["tempDamage"] = Player.temporaryUpgrades["damage"]
	Player.temporaryUpgrades["damage"] = INF


func endGlassCannon() -> void:
	ability1Active = true
	print(ability1Store["tempDamage"])
	Player.temporaryUpgrades["damage"] = ability1Store["tempDamage"]
	ability1Store["tempDamage"] = {}
