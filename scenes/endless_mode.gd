extends Node


signal endOfRound


const nBoxRows: int = 18
const boxesPerRow: int = 10
const boxMargin: int = 5

var boxFieldReady: bool = false
var continuedOnce: bool = false
var ballSpeed
var nBalls: int
var nBallsSpawned: int = 0
var nBallsDespawned: int = 0
var score: int = 0

var deathTime: int
var deathTimeRemaining: int :
	set(newDTR):
		deathTimeRemaining = newDTR
		$ScoreBar.setDeathTimer(newDTR)


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	%PlayingField.ballDespawned.connect(_on_ball_despawned)
	%PlayingField.requestCalculateOnBoxCollision.connect(%EntityField.calculateOnBoxCollision)
	%PlayingField.requestResolveOnBoxCollision.connect(%EntityField.resolveOnBoxCollision)
	%PlayingField.canvasClicked.connect(_on_click_on_playingfield)
	
	%EntityField.readyAndRendered.connect(_on_box_field_ready)
	%EntityField.boxDestruction.connect(_on_box_destruction)
	%EntityField.collectUpgrade.connect(_on_collect_upgrade)
	%EntityField.gameover.connect(_on_gameover)
	
	$GameOverDialog.continueGame.connect(_on_gameover_continue_game)
	$GameOverDialog.restartGame.connect(_on_gameover_restart_game)
	$GameOverDialog.endGame.connect(_on_gameover_end_game)
	
	Player.dataChanged.connect(_on_player_data_changed)
	
	%Abilities.abilityUsed.connect(_on_use_ability)
	setup()


func _process(_delta: float) -> void:
	pass


# ========================================
# ========= Custom Methods ===============
# ========================================
func setup() -> void:
	GlobalDefinitions.loadRewardInterstitial()
	deathTime = Player.getUpgrade("deathTime")
	nBalls = Player.getUpgrade("nBalls")
	$ScoreBar.setBallNumber(nBalls)
	$ScoreBar.setDamage(Player.getUpgrade("damage"))
	$ProgressBar.max_value = 0
	$ProgressBar.max_value = Player.getUpgrade("ballProgressCost") + \
		(nBalls - 1) * Player.getUpgrade("ballProgressPerLevelCost")
	
	# Reset temporary player state
	for upgrade in Player.temporaryUpgrades:
		Player.temporaryUpgrades[upgrade] = 0
	roundReset()


func roundReset() -> void:
	endOfRound.emit()
	nBallsDespawned = 0
	deathTimeRemaining = deathTime
	
	stopRunning()
	%Abilities.onRoundReset()
	$BallSpawnTimer.stop()
	$DeathTimer.stop()
	Player.onRoundReset()
	
	if boxFieldReady: %EntityField.walk()
	
	# Free all spawned balls and resets collision list
	%PlayingField.reset()
	CollisionList.reset()
	
	# Instantiate first ball at origin
	%PlayingField.spawnBall(%StartPosition.position, Vector2.ZERO, false)
	nBallsSpawned = 1


func startRunning() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.RUNNING
	%Abilities.onRoundStart()
	set_process(true)
	
	$BallSpawnTimer.start()
	$DeathTimer.start()


func stopRunning() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.HALTING
	set_process(false)


func spawnBall() -> void:
	%PlayingField.spawnBallAt(%StartPosition.position)
	nBallsSpawned += 1


# ========================================
# ========= Signals ======================
# ========================================
func _on_click_on_playingfield(location: Vector2) -> void:
	if GlobalDefinitions.State.HALTING == GlobalDefinitions.state:
		startRunning()
		
		var trajectory = location - %StartPosition.position
		var flankAngleBonus = 1 - (Player.getUpgrade("ballProgressFlankAngle") / 90.)
		var spawnAngle = 90. - flankAngleBonus * abs(trajectory.angle_to(Vector2.UP)) * 180 / PI
		if $ProgressBar.value + spawnAngle > $ProgressBar.max_value:
			$ProgressBar.value = $ProgressBar.value + spawnAngle - $ProgressBar.max_value
			nBalls += 1
			Player.incrementTemporaryUpgrade("nBalls", 1)
			$ScoreBar.setBallNumber(nBalls)
			$ProgressBar.max_value = Player.getUpgrade("ballProgressCost") + \
				(nBalls - 1) * Player.getUpgrade("ballProgressPerLevelCost")
		else:
			$ProgressBar.value += spawnAngle


func _on_ball_despawned() -> void:
	nBallsDespawned += 1
	
	if nBallsSpawned == nBallsDespawned:
		$DeathTimer.stop() # manual stop to prevent to independent round end events
		await get_tree().create_timer(0.1).timeout # Short timer between rounds
		roundReset()


func _on_box_field_ready() -> void:
	boxFieldReady = true
	for i in 3:
		%EntityField.walk()


func _on_box_destruction(details: String, scorePoints: int) -> void:
	score += scorePoints
	$ScoreBar.setScore(score)
	var boxName = details.split("-")[0]
	CollisionList.removeBoxFromCollisionList(boxName)


func _on_collect_upgrade(details: String, type: GlobalDefinitions.EntityType) -> void:
	match type:
		GlobalDefinitions.EntityType.Damage:
			Player.incrementTemporaryUpgrade("damage", 0.5)
		GlobalDefinitions.EntityType.TimeUp:
			deathTime += 1
			deathTimeRemaining += 1
		GlobalDefinitions.EntityType.Currency:
			Player.state["currency"]["standard"] += 1
			Player.saveState()
		GlobalDefinitions.EntityType.PremiumCurrency:
			Player.state["currency"]["premium"] += 1
			Player.saveState()
		GlobalDefinitions.EntityType.Charge:
			Player.addCharge()
	
	var boxName = details.split("-")[0]
	CollisionList.removeBoxFromCollisionList(boxName)


func _on_gameover() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.GAMEOVER
	set_process(false)
	$GameOverDialog.show()
	$GameOverDialog.setRewardAmount(%EntityField.currencyReward())
	if continuedOnce:
		$GameOverDialog.hideContinue()


func _on_gameover_continue_game() -> void:
	%EntityField.cleanRowsOnContinue()
	$GameOverDialog.hide()
	await get_tree().create_timer(0.1).timeout
	stopRunning()
	continuedOnce = true
	GlobalDefinitions.showRewardInterstitial()


func _on_gameover_restart_game() -> void:
	Player.reset()
	%EntityField.reset()
	%PlayingField.reset()
	CollisionList.reset()
	$GameOverDialog.hide()
	$GameOverDialog.showContinue()
	Player.endOfGameUpdates(score, %EntityField.currencyReward())
	await get_tree().create_timer(0.1).timeout
	continuedOnce = false
	boxFieldReady = false
	setup()
	_on_box_field_ready()


func _on_gameover_end_game() -> void:
	Player.reset()
	CollisionList.reset()
	Player.endOfGameUpdates(score, %EntityField.currencyReward())
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_player_data_changed(id: String, value) -> void:
	match id:
		"nBalls":
			nBalls = value
			$ScoreBar.setBallNumber(value)
		"damage":
			$ScoreBar.setDamage(value)
		_:
			pass


func _on_use_ability(abilityId: String) -> void:
	match abilityId:
		"Pass":
			pass
		
		# pre round abilities#
		
		# end round abilities
		"SuddenStop":
			roundReset()
		
		# minor abilities
		"GlassCannon":
			AbilityDefinitions.startGlassCannon(%EntityField.nRows)
			var lambda = func(ball) -> void:
					# TODO: Do not trigger for upgrades
					AbilityDefinitions.endGlassCannon()
					%PlayingField.despawnBall(ball)
			%EntityField.boxHit.connect(lambda, CONNECT_ONE_SHOT)
		
		_:
			AbilityDefinitions.factory[abilityId]["start"].call()
			connect(
				AbilityDefinitions.factory[abilityId]["signal"],
				AbilityDefinitions.factory[abilityId]["end"],
				CONNECT_ONE_SHOT
			)


func _on_ball_spawn_timer_timeout() -> void:
	if nBallsSpawned == nBalls:
		return
	spawnBall()


func _on_death_timer_timeout() -> void:
	deathTimeRemaining -= 1
	if deathTimeRemaining <= 0:
		roundReset()
