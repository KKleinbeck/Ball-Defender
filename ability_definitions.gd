extends Node


var factory: Dictionary = {}


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	for ability in Player.abilityDetails:
		factory[ability] = {"active": false}
	
	factory["BallHell"].merge({
		"signal": "endOfRound",
		"start": startBallHell,
		"end": endBallHell
	})
	factory["DoubleDamage"].merge({
		"signal": "endOfRound",
		"start": startDoubleDamage,
		"end": endDoubleDamage
	})


# ========================================
# ===========  Abilities =================
# ========================================
func startBallHell() -> void:
	factory["BallHell"].active = true
	Player.setEffectUpgrade("BallHell", "nBalls", Player.getUpgrade("nBalls"))


func endBallHell() -> void:
	factory["BallHell"].active = false
	Player.removeEffectUpgrade("BallHell")


func startDoubleDamage() -> void:
	factory["DoubleDamage"].active = true
	Player.setEffectUpgrade("DoubleDamage", "damage", Player.getUpgradeWithoutEffects("damage"))


func endDoubleDamage() -> void:
	factory["DoubleDamage"].active = false
	Player.removeEffectUpgrade("DoubleDamage")


func startGlassCannon() -> void:
	factory["GlassCannon"].active = true
	Player.setEffectUpgrade("GlassCannon", "damage", INF)


func endGlassCannon() -> void:
	factory["GlassCannon"].active = false
	Player.removeEffectUpgrade("GlassCannon")
