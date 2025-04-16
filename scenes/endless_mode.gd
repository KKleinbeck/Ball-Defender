extends Node


#signal gameover(score)

@export var ballProgressAngleRequired: int = 360
#@export var ballDiameterRatio: float = 0.02
#@export var ballSpeedRatio: float = 0.6

const nBoxRows: int = 18
const boxesPerRow: int = 10
const boxMargin: int = 5

var ballSpeed
var nBalls: int = 1
var nBallsSpawned: int = 0
var nBallsDespawned: int = 0

var deathTime: int = 5
var deathTimeRemaining: int :
	set(newDTR):
		deathTimeRemaining = newDTR
		$ScoreBar.setDeathTimer(newDTR)


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	%PlayingField.ballDespawned.connect(_on_ball_despawned)
	%PlayingField.canvasClicked.connect(_on_click_on_playingfield)
	
	$ScoreBar.setBallNumber(nBalls)
	$ProgressBar.max_value = ballProgressAngleRequired
	#updateScore()
	roundReset()


func _process(_delta: float) -> void:
	pass


# ========================================
# ========= Custom Methods ===============
# ========================================
func roundReset() -> void:
	nBallsDespawned = 0
	deathTimeRemaining = deathTime
	
	stopRunning()
	$BallSpawnTimer.stop()
	$DeathTimer.stop()
	
	#$Boxes.walk()
	
	# Free all spawned balls and resets collision list
	%PlayingField.reset()
	CollisionList.purge()
	
	# Instantiate first ball at origin
	%PlayingField.spawnBall(%StartPosition.position, Vector2.ZERO, false)
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
	%PlayingField.spawnBallAt(%StartPosition.position)
	nBallsSpawned += 1


# ========================================
# ========= Signals ======================
# ========================================
func _on_click_on_playingfield(location: Vector2) -> void:
	if GlobalDefinitions.State.HALTING == GlobalDefinitions.state:
		startRunning()
		
		var trajectory = location - %StartPosition.position
		var spawnAngle = 90. - abs(trajectory.angle_to(Vector2.UP)) * 180 / PI
		if $ProgressBar.value + spawnAngle > $ProgressBar.max_value:
			$ProgressBar.value = $ProgressBar.value + spawnAngle - $ProgressBar.max_value
			nBalls += 1
			$ScoreBar.setBallNumber(nBalls)
		else:
			$ProgressBar.value += spawnAngle


func _on_ball_despawned() -> void:
	nBallsDespawned += 1
	
	if nBallsSpawned == nBallsDespawned:
		await get_tree().create_timer(0.1).timeout # Short timer between rounds
		roundReset()


func _on_ball_spawn_timer_timeout() -> void:
	if nBallsSpawned == nBalls:
		$BallSpawnTimer.stop()
		return
	spawnBall()


func _on_death_timer_timeout() -> void:
	deathTimeRemaining -= 1
	if deathTimeRemaining <= 0:
		roundReset()
