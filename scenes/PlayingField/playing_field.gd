extends Control


signal gainedScore(gain: int)
signal startOfRound(v0: Vector2)
signal endOfRound
signal ballDespawned
signal gameover
signal deathTimeIncreased(value)
signal resetRound


@export var instantiateEntities: bool = true

var boxFieldReady: bool = false

var ballObj: PackedScene = load("res://scenes/PlayingField/ball.tscn")
var ballDict: Dictionary = {}
var ballSpeed = 450
var v0 = Vector2.DOWN


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	CollisionList.requestCollisionUpdate.connect(calculateNextCollision)
	
	%Canvas.cursorReleased.connect(_on_cursor_released)
	
	if instantiateEntities:
		%EntityField.readyAndRendered.connect(_on_box_field_ready)
		%EntityField.boxDestruction.connect(_on_box_destruction)
		%EntityField.collectUpgrade.connect(_on_collect_upgrade)
		%EntityField.gameover.connect(func (): gameover.emit())
	
	%ObjectField.laserPointerStart = %StartPosition.position
	%ObjectField.queryPortalSpaceAvailable.connect(_on_query_portal_space)
	%ObjectField.requestLaserTrace.connect(_on_request_laser_trace)
	
	%Abilities.abilityUsed.connect(_on_use_ability)


func _process(delta: float) -> void:
	var deltaRamining = delta
	while deltaRamining > 0.:
		if CollisionList.isEmpty():
			break # E.g. after deletion of last ball
		
		var collisionEvent = CollisionList.last()
		if deltaRamining < collisionEvent["t"]:
			propagate(deltaRamining)
			deltaRamining = 0.
			break
		
		deltaRamining -= collisionEvent["t"]
		propagate(collisionEvent["t"])
		resolveCollision(collisionEvent)
		CollisionList.triggerUpdateFor(collisionEvent["ball"])


func propagate(delta: float) -> void:
	for event in CollisionList.entries:
		event["t"] -= delta
	for ball in ballDict:
		ballDict[ball].propagate(delta)


# ========================================
# ========= Ball Spawning ================
# ========================================
func isValidSpawnPosition(spawnPosition: Vector2) -> bool:
	if spawnPosition.x < position.x or \
	   spawnPosition.x > position.x + size.x or \
	   spawnPosition.y < position.y or \
	   spawnPosition.y > position.y + size.y:
		return false
	return true


func initiateFirstBall():
	spawnBall(%StartPosition.position, v0, false)


func spawnBall(spawnPosition: Vector2 = %StartPosition.position, spawnVelocity: Vector2 = v0, determineCollision: bool = true):
	var newBall = ballObj.instantiate()
	newBall.position = spawnPosition
	newBall.velocity = spawnVelocity
	add_child(newBall)
	ballDict[newBall.name] = newBall
	if determineCollision:
		calculateNextCollision(newBall)
	if ballDict.size() == 1:
		newBall.toggleDebug()


func despawnBall(ball: Node) -> void:
	freeBall(ball)
	CollisionList.removeBall(ball)
	ballDespawned.emit()


func freeBall(ball: Object) -> void:
	ball.queue_free()
	ballDict.erase(ball.name)


func reset() -> void:
	endOfRound.emit()
	%Abilities.onRoundReset()
	if boxFieldReady: %EntityField.walk()
	
	for ballName in ballDict:
		ballDict[ballName].queue_free()
	ballDict = {}


func restart() -> void:
	boxFieldReady = false
	reset()
	%EntityField.reset()
	_on_box_field_ready()


func gameoverContinue() -> void:
	%EntityField.cleanRowsOnContinue()


func currencyReward() -> int:
	return %EntityField.currencyReward()


# ========================================
# ========= Collision Handling ===========
# ========================================
func calculateNextCollision(ball) -> void:
	if ball.is_queued_for_deletion():
		return
	var collisionEvent = {"ball": ball, "t": INF}
	%Canvas.calculateOnCanvasCollision(ball, collisionEvent)
	%ObjectField.calculateOnObjectCollision(ball, collisionEvent)
	%EntityField.calculateOnEntityCollision(ball, collisionEvent)
	if AbilityDefinitions.factory["Phantom"].active == false:
		calculateOnBallCollision(ball, collisionEvent)
	
	CollisionList.add(collisionEvent)


func calculateOnBallCollision(ball, collisionEvent: Dictionary) -> void:
	for otherName in ballDict:
		if otherName == ball.name:
			continue
		var other = ballDict[otherName]
		var deltaP = other.position - ball.position
		var deltaV = other.velocity - ball.velocity
		var collisionDist = (other.diameter + ball.diameter) / 2
		
		var a = pow(deltaV.length(), 2)
		var b = 2. * deltaP.dot(deltaV)
		if b >= 0.: # Balls drifting apart
			continue
		var c = pow(deltaP.length(), 2) - collisionDist*collisionDist
		
		var discriminant = b*b - 4*a*c
		if discriminant < 0:
			continue
		
		var tCollision = (-b - pow(discriminant, 0.5)) / (2*a)
		GlobalDefinitions.updateCollisionEvent(
			collisionEvent, tCollision, "Ball", other,
			ball.position + ball.velocity * tCollision, ball.velocity # Implicit update in resolution method
		)


func resolveCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	ball.position = collisionEvent["collision location"]
	ball.velocity = collisionEvent["post velocity"]
	
	match collisionEvent["partner"]:
		"Canvas":
			if collisionEvent["partner details"] == "Void":
				despawnBall(collisionEvent["ball"])
		
		"Ball":
			resolveOnBallCollision(collisionEvent)
		
		"Entity":
			%EntityField.resolveOnEntityCollision(collisionEvent)
		
		"Object":
			pass


func resolveOnBallCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	var other = collisionEvent["partner details"]
	
	# See Wikipedia - Elastic collision
	if AbilityDefinitions.factory["Phantom"].active == false:
		var deltaPDir = (ball.position - other.position).normalized()
		var deltaVProj = (ball.velocity - other.velocity).dot(deltaPDir)
		
		var m1 = ball.mass
		var m2 = other.mass
		
		ball.velocity  -= 2 * m2 * deltaVProj * deltaPDir / (m1 + m2)
		other.velocity += 2 * m1 * deltaVProj * deltaPDir / (m1 + m2)
	
	CollisionList.triggerUpdateFor(collisionEvent["partner details"])


# ========================================
# ========= Signal handling ==============
# ========================================
func _on_cursor_released(_clickStartLocation: Vector2, clickLocation: Vector2) -> void:
	if ballDict.size() == 1 and GlobalDefinitions.State.HALTING == GlobalDefinitions.state:
		var ball = ballDict[ballDict.keys()[0]]
		v0 = (clickLocation - ball.position).normalized() * ballSpeed
		ball.velocity = v0
		calculateNextCollision(ball)
		startOfRound.emit(v0)
		%Abilities.onRoundStart()


func _on_box_field_ready() -> void:
	boxFieldReady = true
	for i in 3:
		%EntityField.walk()


func _on_box_destruction(details: String, scorePoints: int) -> void:
	gainedScore.emit(scorePoints)
	var boxName = details.split("-")[0]
	CollisionList.removeBoxFromCollisionList(boxName)


func _on_collect_upgrade(details: String, type: GlobalDefinitions.EntityType) -> void:
	match type:
		GlobalDefinitions.EntityType.Damage:
			Player.incrementTemporaryUpgrade("damage", 0.25)
		GlobalDefinitions.EntityType.TimeUp:
			Player.incrementTemporaryUpgrade("deathTime", 1)
			deathTimeIncreased.emit(1)
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


func _on_query_portal_space(location: Vector2, radius: float) -> void:
	%ObjectField.portalSpaceAvailable = %EntityField.isSpaceAvailable(location, radius)


func _on_request_laser_trace(start: Vector2, direction: Vector2) -> void:
	%ObjectField.laserPointerPoints = getLaserTraceRecursive(start, direction, 3)


func getLaserTraceRecursive(start: Vector2, direction: Vector2, n: int) -> PackedVector2Array:
	var result = PackedVector2Array([start])
	var nextCollision = %Canvas.calculateNextCollision(start, direction)
	var entityCollision = %EntityField.calculateNextCollision(start, direction)
	var objectCollision = %ObjectField.calculateNextCollision(start, direction)
	if entityCollision["t"] < nextCollision["t"]:
		nextCollision = entityCollision
	if objectCollision["t"] < nextCollision["t"]:
		nextCollision = objectCollision
	
	if not "collision location" in nextCollision: return result
	if "upgrade" in nextCollision["partner details"]: n += 1
	
	if n > 0:
		if "portal" in nextCollision["partner details"]:
			result.append(start + nextCollision["t"] * direction)
			result.append(Vector2.INF)
		result.append_array(getLaserTraceRecursive(
			nextCollision["collision location"], nextCollision["post velocity"], n - 1
		))
		return result
	
	if (start - nextCollision["collision location"]).length() >= 50.:
		result.append(start + 50 * direction)
	else: result.append(nextCollision["collision location"])
	return result


func _on_use_ability(abilityId: String) -> void:
	match abilityId:
		"Pass":
			pass
		
		# pre round abilities#
		
		# end round abilities
		"SuddenStop":
			resetRound.emit()
		
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
