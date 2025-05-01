extends Control


signal readyAndRendered()
signal boxHit(ball)
signal boxDestruction(details, scorePoints)
signal collectUpgrade(details, type)
signal gameover()


@export var boxes: PackedScene
@export var upgrades: PackedScene


var isReady: bool = false
var gameCanvas: Rect2
var gridConstant: int
var margin: int = 5
var nRows: int = 0


func _process(_delta: float) -> void:
	if not isReady:
		isReady = true
		gridConstant = int(size.x / GlobalDefinitions.boxesPerRow)
		readyAndRendered.emit()
	set_process(false)


func reset() -> void:
	nRows = 0
	for entity in get_children():
		entity.queue_free()


func currencyReward() -> int:
	return nRows * Player.upgrades["currencyRewardPerLevel"]


func cleanRowsOnContinue() -> void:
	var nRowsCleared = Player.upgrades["clearRowsOnRestart"]
	for entity in get_children():
		if entity is Polygon2D and entity.polygon[3].y + nRowsCleared * gridConstant > size.y:
			entity.queue_free()
		elif entity.position.y + 1.5 * gridConstant > size.y: # Only last row of upgrades
			entity.queue_free()


func newBoxAtColumnRow(x: int, y: int) -> Polygon2D:
	var start = position + gridConstant * Vector2(x, y)
	
	var box = boxes.instantiate()
	var health = nRows - randi_range(0, 1) * int(nRows / 2.)
	box.setup(gridConstant, margin, start, health)
	add_child(box)
	return box


func newBenefitAtColumnRow(x: int, y: int, type: GlobalDefinitions.EntityType) -> TextureRect:
	var start = position + gridConstant * Vector2(x, y)
	
	var upgrade = upgrades.instantiate()
	upgrade.createBenefit(gridConstant, start, type)
	add_child(upgrade)
	return upgrade


func newRow() -> void:
	nRows += 1
	
	# Determining number and location of boxes
	var nBoxes = randi_range(3, 6)
	
	var boxLocation = []
	for n in GlobalDefinitions.boxesPerRow:
		if n < nBoxes:
			boxLocation.append(GlobalDefinitions.EntityType.Standard)
		else:
			boxLocation.append(GlobalDefinitions.EntityType.Empty)
	if randf() < Player.upgrades["probDamage"]:
		boxLocation[-3] = GlobalDefinitions.EntityType.Damage
	elif randf() < Player.upgrades["probCharge"]:
		boxLocation[-3] = GlobalDefinitions.EntityType.Charge
	if randf() < Player.upgrades["probDeathTime"]:
		boxLocation[-2] = GlobalDefinitions.EntityType.TimeUp
	if randf() < chanceCurrency("Currency"):
		boxLocation[-1] = GlobalDefinitions.EntityType.Currency
	elif randf() < chanceCurrency("PremiumCurrency"): # Do not spawn currency and and premium at the same time
		boxLocation[-1] = GlobalDefinitions.EntityType.PremiumCurrency
	boxLocation.shuffle()
	
	for n in GlobalDefinitions.boxesPerRow:
		match boxLocation[n]:
			GlobalDefinitions.EntityType.Empty:
				continue
			GlobalDefinitions.EntityType.Standard:
				newBoxAtColumnRow(n, 0)
			_:
				newBenefitAtColumnRow(n, 0, boxLocation[n])


func chanceCurrency(type: String) -> float:
	var p0 = Player.upgrades["prob" + type]
	var pinf = Player.upgrades["prob" + type + "Eventually"]
	return pinf + (p0 - pinf) / (1. + (nRows - 1.) / 50.)


func walk() -> void:
	for entity in get_children():
		if (entity is Polygon2D and entity.polygon[3].y + 1.5 * gridConstant > size.y) or \
		   entity.position.y + gridConstant > size.y:
			gameover.emit()
			return
		entity.walk()
	newRow()


func isSpaceAvailable(objectPosition: Vector2, radius: float) -> bool:
	for entity in get_children():
		if entity.is_queued_for_deletion(): continue
		if (entity.center - objectPosition).length() < radius + entity.radius:
			return false
	return true


func calculateOnEntityCollision(ball, collisionEvent: Dictionary) -> void:
	var geometricCollisionData = calculateNextCollision(ball.position, ball.velocity, ball.debugMode)
	if geometricCollisionData["t"] < INF:
		GlobalDefinitions.updateCollisionEventFromGeometricData(
			collisionEvent, "Entity", geometricCollisionData
		)


func calculateNextCollision(objectPosition: Vector2, objectVelocity:Vector2, debugMode: bool = false) -> Dictionary:
	var trajDir = objectVelocity.normalized()
	var boxWidth = gridConstant - 2 * margin
	var ballRadius = GlobalDefinitions.ballRadius
	var wallCollDist = 0.5 * boxWidth + ballRadius
	var geometricCollisionData = {"t": INF}
	
	for entity in get_children():
		if entity.is_queued_for_deletion(): continue
		
		var deltaPos = entity.center - objectPosition
		var signedLongDist = deltaPos.dot(trajDir)
		var signedOrthoDist = deltaPos.cross(trajDir)
		if signedLongDist < 0 or abs(signedOrthoDist) > ballRadius + entity.radius:
			if debugMode and entity is Polygon2D: entity.color = Color(1, 1, 1)
			continue
		
		if entity is TextureRect:
			var distAtCollision = entity.radius + ballRadius
			
			var travelDist = Math.travelDist(signedLongDist, signedOrthoDist, distAtCollision)
			var tCollision = travelDist / objectVelocity.length()
			GlobalDefinitions.updateGeometricCollision(
				geometricCollisionData, tCollision, entity.name + "-upgrade",
				entity.center - 0.999 * distAtCollision * trajDir.rotated(asin(-signedOrthoDist / distAtCollision)),
				objectVelocity
			)
		
		if entity is Polygon2D:
			# check if ball traveling towards box and box within potential collision range
			if debugMode: entity.color = Color(0, 0, 1)
			
			# side wall collision
			var horDist = deltaPos.x - sign(trajDir.x) * wallCollDist
			var tCollision = horDist / objectVelocity.x
			if abs(deltaPos.y - objectVelocity.y * tCollision) < 0.5 * boxWidth:
				GlobalDefinitions.updateGeometricCollision(
					geometricCollisionData, tCollision, entity.name + "-horizontal",
					objectPosition + objectVelocity * tCollision,
					Vector2(-objectVelocity.x, objectVelocity.y)
				)
			
			var vertDist = deltaPos.y - sign(trajDir.y) * wallCollDist
			tCollision = vertDist / objectVelocity.y
			if abs(deltaPos.x - objectVelocity.x * tCollision) < 0.5 * boxWidth:
				GlobalDefinitions.updateGeometricCollision(
					geometricCollisionData, tCollision, entity.name + "-vertical",
					objectPosition + objectVelocity * tCollision,
					Vector2(objectVelocity.x, -objectVelocity.y)
				)
			
			# Corner collision
			for i in 4:
				var cornerToBall = entity.polygon[i] - objectPosition
				signedOrthoDist = cornerToBall.cross(trajDir)
				if abs(signedOrthoDist) > ballRadius: continue
				var travelDist = Math.travelDist(cornerToBall.dot(trajDir), signedOrthoDist, ballRadius)
				tCollision = travelDist / objectVelocity.length()
				var collisionLocation = objectPosition + objectVelocity * tCollision #entity.polygon[i] - objectRadius * trajDir.rotated(asin(-signedOrthoDist / objectRadius))
				GlobalDefinitions.updateGeometricCollision(
					geometricCollisionData, tCollision, entity.name + "-corner" + str(i), collisionLocation,
					objectVelocity.bounce((entity.polygon[i] - collisionLocation).normalized())
				)
	return geometricCollisionData


func resolveOnEntityCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	var boxName = collisionEvent["partner details"].split("-")[0]
	var entity = get_children().filter(func(x): return x.name == boxName)[0]
	
	if collisionEvent["partner details"].contains("upgrade"):
		entity.queue_free()
		collectUpgrade.emit(collisionEvent["partner details"], entity.type)
		return
	
	# Box destruction
	entity.applyDamage()
	boxHit.emit(ball)
	if entity.health <= 0:
		entity.queue_free()
		boxDestruction.emit(collisionEvent["partner details"], entity.initialHealth)
