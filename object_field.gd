extends Control


signal queryPortalSpaceAvailable(location: Vector2, portalRadius: float)
signal requestLaserTrace(start: Vector2, direction: Vector2)


const laserDotDistance: float = 25.


var laserPointerActive: bool = false
var laserPointerStart: Vector2
var laserPointerPoints: PackedVector2Array
var phase: float = 0

var portalSpaceAvailable: bool = false


var playerPortals: Array = []
var barriers: Array = []


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	AbilityDefinitions.laserPointerDeactivated.connect(deactivateLaserPointer)
	AbilityDefinitions.portalsDeactivated.connect(deactivatePlayerPortals)
	AbilityDefinitions.shieldDeactivated.connect(deactivateShield)


func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var cursorLocation = get_local_mouse_position()
		if AbilityDefinitions.factory.LaserPointer.active:
			var direction = (cursorLocation - laserPointerStart).normalized()
			var start = laserPointerStart + 20 * direction
			requestLaserTrace.emit(start, direction)
			
			phase += 15 * delta
			if phase > laserDotDistance: phase -= laserDotDistance
			queue_redraw()


func _input(event: InputEvent) -> void:
	if not Player.state.isDrawing: return
	
	if event is InputEventMouseButton and event.pressed == false:
		if AbilityDefinitions.factory.Portal.active:
			var portal = load("res://scenes/Objects/portal.tscn").instantiate()
			var portalPosition = get_local_mouse_position()
			var portalDiameter = size.x / GlobalDefinitions.boxesPerRow
			queryPortalSpaceAvailable.emit(portalPosition, 0.5 * portalDiameter)
			
			if portalSpaceAvailable:
				portalSpaceAvailable = false
				portal.setup(portalPosition, portalDiameter * Vector2(1, 1))
				add_child(portal)
				playerPortals.append(portal)
				AbilityDefinitions.factory.Portal.count += 1
				if AbilityDefinitions.factory.Portal.count >= 2:
					Player.state.isDrawing = false


func _draw():
	if AbilityDefinitions.factory.LaserPointer.active and laserPointerPoints.size() > 1:
		var distance = Math.totalLength(laserPointerPoints) - phase
		if distance > 0:
			for n in int(distance / laserDotDistance) + 1:
				draw_circle(
					Math.pointAtDistance(n * laserDotDistance + phase, laserPointerPoints),
					4., Color.WHITE, true, -1.0, true
				)


# ========================================
# ========= Custom Methods ===============
# ========================================
func deactivateLaserPointer() -> void:
	queue_redraw()


func deactivatePlayerPortals() -> void:
	for portal in playerPortals:
		portal.queue_free()
	playerPortals = []


func deactivateShield() -> void:
	if AbilityDefinitions.factory.Shield.active:
		barriers[0].queue_free()
		barriers = []


func createShield(yPosition) -> void:
	var shield = load("res://scenes/Objects/Shield.tscn").instantiate()
	shield.position.x = GlobalDefinitions.ballRadius
	shield.position.y = yPosition
	shield.size.x = size.x - 2 * GlobalDefinitions.ballRadius
	shield.z_index = 1
	add_child(shield)
	barriers.append(shield)


# ========================================
# ========= Collision Handling ===========
# ========================================
func calculateOnObjectCollision(ball, collisionEvent: Dictionary) -> void:
	var geometricCollisionData = calculateNextCollision(ball.position, ball.velocity)
	if geometricCollisionData["t"] < INF:
		GlobalDefinitions.updateCollisionEventFromGeometricData(
			collisionEvent, "Object", geometricCollisionData
		)


func calculateNextCollision(ballPosition: Vector2, ballVelocity: Vector2) -> Dictionary:
	var geometricCollisionData = {"t": INF}
	var trajDir = ballVelocity.normalized()
	for n in playerPortals.size():
		var portal = playerPortals[n]
		var deltaPos = portal.position + portal.pivot_offset - ballPosition
		var signedLongDist = deltaPos.dot(trajDir)
		var signedOrthoDist = deltaPos.cross(trajDir)
		var distAtCollision = portal.size.x / 2 - GlobalDefinitions.ballRadius
		if signedLongDist < 0 or abs(signedOrthoDist) > distAtCollision: continue
		
		var travelDist = Math.travelDist(signedLongDist, signedOrthoDist, distAtCollision)
		var tCollision = travelDist / ballVelocity.length()
		var collisionLocation = playerPortals[1].position if n == 0 else playerPortals[0].position
		collisionLocation += portal.pivot_offset + distAtCollision * trajDir
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Portal" + str(n),
			collisionLocation, ballVelocity
		)
	
	if AbilityDefinitions.factory.Shield.active and ballVelocity.y > 0 and barriers.size() > 0:
		var tCollision = (barriers[0].position.y - ballPosition.y + 2 - GlobalDefinitions.ballRadius) / ballVelocity.y
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, "Shield",
			ballPosition + ballVelocity * tCollision, Vector2(ballVelocity.x, -ballVelocity.y)
		)
	return geometricCollisionData


func resolveOnEntityCollision(collisionEvent: Dictionary) -> void:
	# Clear balls after shield is dead
	if collisionEvent["partner details"] == "Shield":
		barriers[0].self_modulate.a = AbilityDefinitions.damageShield()
