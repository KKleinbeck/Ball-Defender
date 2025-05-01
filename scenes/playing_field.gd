extends ColorRect


signal ballDespawned
signal startOfRound
signal cursorDragStart(start: Vector2)
signal cursorReleased(start: Vector2, end: Vector2)
signal requestCalculateOnBoxCollision(ball: Node, collisionEvent: Dictionary)
signal requestResolveOnBoxCollision(collisionEvent: Dictionary)
signal canvasClicked(location: Vector2)

var pressReadied: bool = false
var pressStartLocation: Vector2
var ballObj: PackedScene = load("res://scenes/PlayingField/ball.tscn")
var ballDict: Dictionary = {}
var ballSpeed = 450
var v0: Vector2 = Vector2(0, -ballSpeed)


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	CollisionList.requestCollisionUpdate.connect(calculateNextCollision)


func _input(event: InputEvent) -> void:
	var clickLocation = get_local_mouse_position()
	if event is InputEventMouseButton and event.pressed:
		if !pressReadied:
			pressStartLocation = clickLocation
		cursorDragStart.emit(pressStartLocation)
		pressReadied = true
	
	if event is InputEventMouseButton and event.pressed == false and pressReadied: # pressed == false => mouse up
		pressReadied = false
		cursorReleased.emit(pressStartLocation, clickLocation)
		# Ignore clicks outside the field or too distant locations
		if clickLocation.y < position.y or clickLocation.y > position.y + size.y or \
		   ( (clickLocation - pressStartLocation).length() > 20 and Player.state.doNotStartOnDrag):
			return
		startOfRound.emit()
		
		if ballDict.size() == 1 and GlobalDefinitions.State.HALTING == GlobalDefinitions.state:
			var ball = ballDict[ballDict.keys()[0]]
			v0 = (clickLocation - ball.position).normalized() * ballSpeed
			ball.velocity = v0
			calculateNextCollision(ball)
		canvasClicked.emit(clickLocation)


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


func spawnBallAt(spawnPosition: Vector2):
	spawnBall(spawnPosition, v0)


func spawnBall(spawnPosition: Vector2, spawnVelocity: Vector2, determineCollision: bool = true):
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
	for ballName in ballDict:
		ballDict[ballName].queue_free()
	ballDict = {}


# ========================================
# ========= Collision Handling ===========
# ========================================
func calculateNextCollision(ball) -> void:
	if ball.is_queued_for_deletion():
		return
	var collisionEvent = {"ball": ball, "t": INF}
	var geometricCollisionData = calculateOnCanvasCollision(ball.position, ball.velocity)
	GlobalDefinitions.updateCollisionEventFromGeometricData(
		collisionEvent, "Canvas", geometricCollisionData
	)
	if AbilityDefinitions.factory["Phantom"].active == false:
		calculateOnBallCollision(ball, collisionEvent)
	calculateOnBoxCollision(ball, collisionEvent)
	
	CollisionList.add(collisionEvent)


func calculateOnCanvasCollision(p: Vector2, v: Vector2) -> Dictionary:
	var r = GlobalDefinitions.ballRadius
	
	var endPosition = position + size
	var geometricCollisionData = {"t": INF}
	if v.x < 0:
		var tCollision = (position.x + r - p.x) / v.x
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Left", Vector2(r, p.y + v.y * tCollision), Vector2(-v.x, v.y)
		)
	else:
		var tCollision = (endPosition.x - r - p.x) / (v.x + 1e-200) # In case v.x == 0
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Right", Vector2(endPosition.x - r, p.y + v.y * tCollision), Vector2(-v.x, v.y)
		)
	if v.y < 0:
		var tCollision = (r - p.y) / v.y
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Top", Vector2(p.x + v.x * tCollision, r), Vector2(v.x, -v.y)
		)
	else:
		var tCollision = (size.y + 2*r - p.y) / (v.y + 1e-200)
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Void", Vector2(p.x + v.x * tCollision, size.y + 2*r), v
		)
	return geometricCollisionData


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


func calculateOnBoxCollision(ball: Node, collisionEvent: Dictionary) -> void:
	requestCalculateOnBoxCollision.emit(ball, collisionEvent)


func resolveCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	#ball.position = collisionEvent["collision location"]
	ball.velocity = collisionEvent["post velocity"]
	
	match collisionEvent["partner"]:
		"Canvas":
			if collisionEvent["partner details"] == "Void":
				despawnBall(collisionEvent["ball"])
		
		"Ball":
			resolveOnBallCollision(collisionEvent)
		
		"Entity":
			requestResolveOnBoxCollision.emit(collisionEvent)


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
