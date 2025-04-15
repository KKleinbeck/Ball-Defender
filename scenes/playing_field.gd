extends ColorRect


signal ballDespawned


var ballObj: PackedScene = load("res://scenes/PlayingField/ball.tscn")
var ballDict = {}


func isValidSpawnPosition(spawnPosition: Vector2) -> bool:
	if spawnPosition.x < position.x or \
	   spawnPosition.x > position.x + size.x or \
	   spawnPosition.y < position.y or \
	   spawnPosition.y > position.y + size.y:
		return false
	return true


func spawnBall(spawnPosition: Vector2, spawnVelocity: Vector2):
	var newBall = ballObj.instantiate()
	# TODO: Provide guarantees for position, i.e. colliding with walls etc
	if !isValidSpawnPosition(spawnPosition):
		push_error("Ball Spawned outside of playing field")
		print(spawnPosition, position, size)
	newBall.position = spawnPosition
	newBall.velocity = spawnVelocity
	add_child(newBall)
	ballDict[newBall.name] = newBall
	calculateNextCollision(newBall)


func despawnBall(ball: Node) -> void:
	#nBallsDespawned += 1
	freeBall(ball)
	CollisionList.removeBall(ball)
	ballDespawned.emit()
	
	#if nBallsSpawned == nBallsDespawned:
		#await get_tree().create_timer(0.1).timeout # Short timer between rounds
		#roundReset()


func freeBall(ball: Object) -> void:
	ball.queue_free()
	ballDict.erase(ball.name)


func _ready() -> void:
	CollisionList.requestCollisionUpdate.connect(calculateNextCollision)


func _process(delta: float) -> void:
	#if state == State.DEBUG_STEP:
		#debugPause()
	
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
# ========= Collision Handling ===========
# ========================================
func updateCollisionEvent(collisionEvent: Dictionary, t: float, partner: String, partner_details, collision_location: Vector2) -> void:
	# TODO: Simultaneous collision events
	if collisionEvent["t"] < t:
		return 
	collisionEvent["t"] = t
	collisionEvent["partner"] = partner
	collisionEvent["partner details"] = partner_details
	collisionEvent["collision location"] = collision_location


func calculateNextCollision(ball) -> void:
	if ball.is_queued_for_deletion():
		return
	var collisionEvent = {"ball": ball, "t": INF}
	calculateOnCanvasCollision(ball, collisionEvent)
	calculateOnBallCollision(ball, collisionEvent)
	#calculateOnBoxCollision(ball, collisionEvent)
	
	CollisionList.add(collisionEvent)


func calculateOnCanvasCollision(ball, collisionEvent: Dictionary) -> void:
	var r = ball.diameter/2
	var p = ball.position
	var v = ball.velocity
	
	var endPosition = position + size
	if v.x < 0:
		var tCollision = (position.x + r - p.x) / v.x
		updateCollisionEvent(collisionEvent, tCollision, "Canvas", "Left", Vector2(r, p.y + v.y * tCollision))
	else:
		var tCollision = (endPosition.x - r - p.x) / (v.x + 1e-200) # In case v.x == 0
		updateCollisionEvent(collisionEvent, tCollision, "Canvas", "Right", Vector2(endPosition.x - r, p.y + v.y * tCollision))
	if v.y < 0:
		var tCollision = (r - p.y) / v.y
		updateCollisionEvent(collisionEvent, tCollision, "Canvas", "Top", Vector2(p.x + v.x * tCollision, r))
	else:
		var tCollision = (size.y + 2*r - p.y) / (v.y + 1e-200)
		updateCollisionEvent(collisionEvent, tCollision, "Canvas", "Void", Vector2(p.x + v.x * tCollision, size.y + 2*r))


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
		updateCollisionEvent(
			collisionEvent, tCollision, "Ball", other, ball.position + ball.velocity * tCollision
		)


func resolveCollision(collisionEvent: Dictionary) -> void:
	#Logger.debug("Resolving collision event:\n\t" + str(collisionEvent))
	
	var ball = collisionEvent["ball"]
	ball.position = collisionEvent["collision location"]
	
	match collisionEvent["partner"]:
		"Canvas":
			resolveOnCanvasCollision(collisionEvent)
		
		"Ball":
			resolveOnBallCollision(collisionEvent)
		
		#"Boxes":
			#resolveOnBoxCollision(collisionEvent)


func resolveOnCanvasCollision(collisionEvent) -> void:
	var ball = collisionEvent["ball"]
	match collisionEvent["partner details"]:
		"Left", "Right":
			ball.velocity.x = -ball.velocity.x
		"Top":
			ball.velocity.y = -ball.velocity.y
		"Void":
			despawnBall(ball)


func resolveOnBallCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	var other = collisionEvent["partner details"]
	
	# See Wikipedia - Elastic collision
	var deltaPDir = (ball.position - other.position).normalized()
	var deltaVProj = (ball.velocity - other.velocity).dot(deltaPDir)
	
	var m1 = ball.mass
	var m2 = other.mass
	
	ball.velocity  -= 2 * m2 * deltaVProj * deltaPDir / (m1 + m2)
	other.velocity += 2 * m1 * deltaVProj * deltaPDir / (m1 + m2)
	
	CollisionList.triggerUpdateFor(collisionEvent["partner details"])
