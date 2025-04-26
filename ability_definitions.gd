extends Node


var factory: Dictionary = {}


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	factory["BallHell"] = {
		"signal": "endOfRound",
		"start": startBallHell,
		"end": endBallHell
	}
	factory["DoubleDamage"] = {
		"signal": "endOfRound",
		"start": startDoubleDamage,
		"end": endDoubleDamage
	}


# ========================================
# ===========  Abilities =================
# ========================================
func startBallHell() -> void:
	Player.setEffectUpgrade("BallHell", "nBalls", Player.getUpgrade("nBalls"))


func endBallHell() -> void:
	Player.removeEffectUpgrade("BallHell")


func startDoubleDamage() -> void:
	Player.setEffectUpgrade("DoubleDamage", "damage", Player.getUpgradeWithoutEffects("damage"))


func endDoubleDamage() -> void:
	Player.removeEffectUpgrade("DoubleDamage")


func startGlassCannon() -> void:
	Player.setEffectUpgrade("GlassCannon", "damage", INF)


func endGlassCannon() -> void:
	Player.removeEffectUpgrade("GlassCannon")
