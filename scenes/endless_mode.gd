extends Node


const nBoxRows: int = 18
const boxesPerRow: int = 10
const boxMargin: int = 5

var continuedOnce: bool = false
var ballSpeed
var nBalls: int
var nBallsSpawned: int = 0
var nBallsDespawned: int = 0
var score: int = 0

var deathTimeRemaining: int :
	set(newDTR):
		deathTimeRemaining = newDTR
		$ScoreBar.setDeathTimer(newDTR)


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	%PlayingField.gainedScore.connect(_on_score_gained)
	%PlayingField.ballDespawned.connect(_on_ball_despawned)
	%PlayingField.startOfRound.connect(_on_start_of_round)
	%PlayingField.gameover.connect(_on_gameover)
	%PlayingField.deathTimeIncreased.connect(func (x): deathTimeRemaining += x)
	%PlayingField.resetRound.connect(roundReset)
	
	$GameOverDialog.continueGame.connect(_on_gameover_continue_game)
	$GameOverDialog.restartGame.connect(_on_gameover_restart_game)
	$GameOverDialog.endGame.connect(_on_gameover_end_game)
	
	Player.dataChanged.connect(_on_player_data_changed)
	
	setup()


func _process(_delta: float) -> void:
	pass


# ========================================
# ========= Custom Methods ===============
# ========================================
func setup() -> void:
	Player.reset()
	GlobalDefinitions.loadRewardInterstitial()
	nBalls = Player.getUpgrade("nBalls")
	$ScoreBar.setBallNumber(nBalls)
	$ScoreBar.setDamage(Player.getUpgrade("damage"))
	$ProgressBar.max_value = Player.state.ballProgressTarget
	
	# Reset temporary player state
	for upgrade in Player.temporaryUpgrades:
		Player.temporaryUpgrades[upgrade] = 0
	roundReset()


func roundReset() -> void:
	nBallsDespawned = 0
	deathTimeRemaining = Player.getUpgrade("deathTime")
	
	stopRunning()
	$BallSpawnTimer.stop()
	$DeathTimer.stop()
	Player.onRoundReset()
	
	# Free all spawned balls and resets collision list
	%PlayingField.reset()
	CollisionList.reset()
	
	# Instantiate first ball at origin
	%PlayingField.initiateFirstBall()
	nBallsSpawned = 1


func startRunning() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.RUNNING
	set_process(true)
	
	$BallSpawnTimer.start()
	$DeathTimer.start()


func stopRunning() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.HALTING
	set_process(false)


func spawnBall() -> void:
	%PlayingField.spawnBall()
	nBallsSpawned += 1


# ========================================
# ========= Signals ======================
# ========================================
func _on_score_gained(gain: int) -> void:
	score += gain
	$ScoreBar.setScore(score)


func _on_ball_despawned() -> void:
	nBallsDespawned += 1
	
	if nBallsSpawned == nBallsDespawned:
		$DeathTimer.stop() # manual stop to prevent to independent round end events
		await get_tree().create_timer(0.1).timeout # Short timer between rounds
		roundReset()


func _on_start_of_round(_ballVelocity: Vector2) -> void:
	if GlobalDefinitions.State.HALTING == GlobalDefinitions.state:
		startRunning()


func _on_gameover() -> void:
	GlobalDefinitions.state = GlobalDefinitions.State.GAMEOVER
	set_process(false)
	$GameOverDialog.show()
	$GameOverDialog.setRewardAmount(%PlayingField.currencyReward())
	if continuedOnce:
		$GameOverDialog.hideContinue()


func _on_gameover_continue_game() -> void:
	%PlayingField.gameoverContinue()
	$GameOverDialog.hide()
	await get_tree().create_timer(0.1).timeout
	stopRunning()
	continuedOnce = true
	GlobalDefinitions.showRewardInterstitial()


func _on_gameover_restart_game() -> void:
	Player.reset()
	%PlayingField.restart()
	CollisionList.reset()
	$GameOverDialog.hide()
	$GameOverDialog.showContinue()
	Player.endOfGameUpdates(score, %PlayingField.currencyReward())
	await get_tree().create_timer(0.1).timeout
	continuedOnce = false
	setup()


func _on_gameover_end_game() -> void:
	Player.reset()
	CollisionList.reset()
	Player.endOfGameUpdates(score, %PlayingField.currencyReward())
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_player_data_changed(id: String, value) -> void:
	match id:
		"ballProgressTarget":
			$ProgressBar.max_value = value
		"ballProgressValue":
			$ProgressBar.value = value
		"nBalls":
			nBalls = value
			$ScoreBar.setBallNumber(value)
		"damage":
			$ScoreBar.setDamage(value)
		_:
			pass


func _on_ball_spawn_timer_timeout() -> void:
	if nBallsSpawned == nBalls:
		return
	spawnBall()


func _on_death_timer_timeout() -> void:
	deathTimeRemaining -= 1
	if deathTimeRemaining <= 0:
		roundReset()
