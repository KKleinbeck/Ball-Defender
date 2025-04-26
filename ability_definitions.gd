extends Node


var abilityStore: Dictionary = {}

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
# ========= Custom Methods ===============
# ========================================
func storeTempUpgrade(ability: String, id: String) -> void:
	if not ability in abilityStore:
		abilityStore[ability] = {}
	abilityStore[ability][id] = Player.temporaryUpgrades[id]


func resetTempUpgrade(ability: String, id: String) -> void:
	Player.setTemporaryUpgrade(id, abilityStore[ability][id])
	abilityStore.erase(ability)


func onUpgradeCollect(id: String, change) -> void:
	# Guarantees that upgrades collected during abilities are added correctly
	for ability in abilityStore:
		if id in abilityStore[ability]:
			abilityStore[ability][id] += change


# ========================================
# ===========  Abilities =================
# ========================================
func startBallHell() -> void:
	storeTempUpgrade("BallHell", "nBalls")
	Player.setTemporaryUpgrade("nBalls", 2 * Player.getUpgrade("nBalls") - Player.upgrades["nBalls"])


func endBallHell() -> void:
	resetTempUpgrade("BallHell", "nBalls")


func startDoubleDamage() -> void:
	storeTempUpgrade("DoubleDamage", "damage")
	Player.incrementTemporaryUpgrade("damage", Player.getUpgrade("damage"))


func endDoubleDamage() -> void:
	resetTempUpgrade("DoubleDamage", "damage")


func startGlassCannon() -> void:
	storeTempUpgrade("GlassCannon", "damage")
	Player.setTemporaryUpgrade("damage", INF)


func endGlassCannon() -> void:
	resetTempUpgrade("GlassCannon", "damage")
