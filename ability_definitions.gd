extends Node


signal laserPointerDeactivated
signal portalsDeactivated
signal shieldDeactivated


var factory: Dictionary = {}


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	for ability in Player.abilityDetails:
		factory[ability] = {"active": false}
	
	factory["AntiGravity"].merge({
		"signal": "endOfRound",
		"start": startAntiGravity,
		"end": endAntiGravity
	})
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
	factory["Phantom"].merge({
		"signal": "endOfRound",
		"start": startPhantom,
		"end": endPhantom
	})
	factory["Portal"].merge({
		"signal": "endOfRound",
		"start": startPortal,
		"end": endPortal
	})
	factory["LaserPointer"].merge({
		"signal": "startOfRound",
		"start": startLaserPointer,
		"end": endLaserPointer
	})


# ========================================
# ===========  Abilities =================
# ========================================
func startAntiGravity() -> void:
	factory["AntiGravity"].active = true
	var antiGravityStop = get_tree().create_timer(2.0)
	antiGravityStop.timeout.connect(endAntiGravity)


func endAntiGravity() -> void:
	factory["AntiGravity"].active = false
	# TODO: This massively changes the collision list every single frame => we should find a work around


func startBallHell() -> void:
	factory["BallHell"].active = true
	Player.setAbilityUpgrade("BallHell", "nBalls", Player.getUpgrade("nBalls"))


func endBallHell() -> void:
	factory["BallHell"].active = false
	Player.removeAbilityUpgrade("BallHell")


func startDoubleDamage() -> void:
	factory["DoubleDamage"].active = true
	Player.setAbilityUpgrade("DoubleDamage", "damage", Player.getUpgradeWithoutEffects("damage"))


func endDoubleDamage() -> void:
	factory["DoubleDamage"].active = false
	Player.removeAbilityUpgrade("DoubleDamage")


func startGlassCannon(nRows: int) -> void:
	factory["GlassCannon"].active = true
	Player.setAbilityUpgrade("GlassCannon", "damage", nRows / 4.)


func endGlassCannon() -> void:
	factory["GlassCannon"].active = false
	Player.removeAbilityUpgrade("GlassCannon")


func startLaserPointer() -> void:
	factory["LaserPointer"].active = true
	Player.state.doNotStartOnDrag = false


func endLaserPointer(_v0: Vector2) -> void:
	factory["LaserPointer"].active = false
	Player.state.doNotStartOnDrag = true
	laserPointerDeactivated.emit()


func startPhantom() -> void:
	factory["Phantom"].active = true


func endPhantom() -> void:
	factory["Phantom"].active = false


func startPortal() -> void:
	factory["Portal"].active = true
	factory["Portal"]["count"] = 0
	Player.state.isDrawing = true


func endPortal() -> void:
	factory["Portal"].active = false
	portalsDeactivated.emit()


func startShield() -> void:
	factory["Shield"].active = true
	factory["Portal"]["life"] = 1 + int(Player.getUpgrade("nBalls") / 3)


func damageShield() -> float:
	factory["Portal"]["life"] -= 1
	if factory["Portal"]["life"] == 0:
		endShield()
	return factory["Portal"]["life"] / (1. + int(Player.getUpgrade("nBalls") / 3))


func endShield() -> void:
	factory["Shield"].active = false
	CollisionList.triggerUpdateByPartnerDetails("Shield")
	shieldDeactivated.emit()
