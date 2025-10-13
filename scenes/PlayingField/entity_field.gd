extends Control


signal readyAndRendered()
signal boxHit(ball)
signal specialHit(ball, type)
signal boxDestruction(details, scorePoints)
signal collectUpgrade(details, type)
signal gameover()


@export var boxes: PackedScene
@export var upgrades: PackedScene
@export var specials: PackedScene
var lighningConduitScene = load("res://scenes/PlayingField/SpecialEntities/LightningConduit.tscn")


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


func newBoxLikeAtColumnRow(x: int, y: int, type: GlobalDefinitions.EntityType):
	var start = position + gridConstant * Vector2(x, y)
	match type:
		GlobalDefinitions.EntityType.Box:
			return newBoxAtPosition(start)
		GlobalDefinitions.EntityType.LightningConduit:
			return newLightningConduitAtPosition(start)
		_:
			pass


func newBoxAtPosition(start: Vector2) -> Box:
	var health = nRows - randi_range(0, 1) * int(nRows / 2.)
	return newBox(start, health, health)


func newLightningConduitAtPosition(start: Vector2) -> Box:
	var health = nRows + randi_range(0, 1) * int(nRows / 2.)
	return newLightningConduit(start, health, health)


func newLightningConduit(start: Vector2, health: int, initialHealth: int) -> Box:
	var lightningConduit = lighningConduitScene.instantiate()
	lightningConduit.setup(gridConstant, margin, start, health, initialHealth)
	add_child(lightningConduit)
	return lightningConduit


func newBox(start: Vector2, health: int, initialHealth: int) -> Box:
	var box = boxes.instantiate()
	box.setup(gridConstant, margin, start, health, initialHealth)
	add_child(box)
	return box


func newBenefitAtColumnRow(x: int, y: int, type: GlobalDefinitions.EntityType) -> TextureRect:
	var start = position + gridConstant * Vector2(x, y)
	return newBenefitAtPosition(start, type)


func newBenefitAtPosition(start: Vector2, type: GlobalDefinitions.EntityType) -> TextureRect:
	var upgrade = upgrades.instantiate()
	upgrade.createBenefit(gridConstant, start, type)
	add_child(upgrade)
	return upgrade


func newSpecialAtPosition(start: Vector2, type, details) -> Node2D:
	var special = specials.instantiate()
	special.create(gridConstant, start, type, details)
	add_child(special)
	return special


func newRow() -> void:
	nRows += 1
	
	if nRows < 6:
		newStandardRow()
	else:
		laserRow()

func newStandardRow() -> void:
	# Determining number and location of boxes
	var nBoxes = randi_range(3, 6)
	
	var entityLocations = []
	for n in GlobalDefinitions.boxesPerRow:
		if n < nBoxes:
			entityLocations.append(GlobalDefinitions.EntityType.Box)
		else:
			entityLocations.append(GlobalDefinitions.EntityType.Empty)
	if randf() < Player.upgrades["probDamage"]:
		entityLocations[-3] = GlobalDefinitions.EntityType.Damage
	elif randf() < Player.upgrades["probCharge"]:
		entityLocations[-3] = GlobalDefinitions.EntityType.Charge
	if randf() < Player.upgrades["probDeathTime"]:
		entityLocations[-2] = GlobalDefinitions.EntityType.TimeUp
	if randf() < chanceCurrency("Currency"):
		entityLocations[-1] = GlobalDefinitions.EntityType.Currency
	elif randf() < chanceCurrency("PremiumCurrency"): # Do not spawn currency and and premium at the same time
		entityLocations[-1] = GlobalDefinitions.EntityType.PremiumCurrency
	entityLocations.shuffle()
	
	createRowFromArray(entityLocations)

func laserRow() -> void:
	var entityLocations = []
	var low = randi_range(0, 2)
	var high = randi_range(1, 3)
	for n in GlobalDefinitions.boxesPerRow:
		if n == low or n == GlobalDefinitions.boxesPerRow - high:
			entityLocations.append(GlobalDefinitions.EntityType.LightningConduit)
		else:
			entityLocations.append(GlobalDefinitions.EntityType.Empty)
			
	var conduits = createRowFromArray(entityLocations)
	var barrier = newSpecialAtPosition(
		Vector2(gridConstant * (low + 1) - margin, 0),
		GlobalDefinitions.EntityType.Lightning,
		{"width": gridConstant * (GlobalDefinitions.boxesPerRow - high - low - 1) + 2 * margin}
	)
	
	for conduit in conduits:
		conduit.associatedBarrierId = barrier.idAtCreation


func createRowFromArray(entityLocations: Array) -> Array:
	var newBoxes = []
	for n in GlobalDefinitions.boxesPerRow:
		match entityLocations[n]:
			GlobalDefinitions.EntityType.Empty:
				continue
			GlobalDefinitions.EntityType.Box:
				newBoxes.append(newBoxLikeAtColumnRow(n, 0, entityLocations[n]))
			GlobalDefinitions.EntityType.LightningConduit:
				newBoxes.append(newBoxLikeAtColumnRow(n, 0, entityLocations[n]))
			_:
				newBenefitAtColumnRow(n, 0, entityLocations[n])
	return newBoxes


func chanceCurrency(type: String) -> float:
	var p0 = Player.upgrades["prob" + type]
	var pinf = Player.upgrades["prob" + type + "Eventually"]
	return pinf + (p0 - pinf) / (1. + (nRows - 1.) / 50.)


func walk() -> void:
	for entity in get_children():
		if (entity is Polygon2D and entity.polygon[3].y + 1.5 * gridConstant > size.y):
			gameover.emit()
			return
		if entity.position.y + gridConstant > size.y:
			entity.queue_free()
			continue
		entity.walk()
	newRow()


func storeGameState() -> void:
	GameState.state.nRows = nRows
	GameState.state.entities = []
	var offset = 0.5 * gridConstant * Vector2(1., 1.)
	for entity in get_children():
		var entry = {
			"type": entity.type,
			"position": entity.center - offset
		}
		if entity is Box:
			entry.initialHealth = entity.initialHealth
			entry.health = entity.health
		elif entity is SpecialNode:
			entry.details = entity.details
			entry.position = entity.position
			entry.idAtCreation = entity.idAtCreation
		if entity.type == GlobalDefinitions.EntityType.LightningConduit:
			entry.associatedBarrierId = entity.associatedBarrierId
		GameState.state.entities.append(entry)


func reloadPreviousGame() -> void:
	nRows = GameState.state.nRows
	
	var dependOnIds = {}
	var newIdMap = {}
	for entity in GameState.state.entities:
		match entity.type:
			GlobalDefinitions.EntityType.Empty:
				pass
			GlobalDefinitions.EntityType.Box:
				newBox(entity.position, entity.health, entity.initialHealth)
			GlobalDefinitions.EntityType.LightningConduit:
				var conduit = newLightningConduit(
					entity.position, entity.health, entity.initialHealth
				)
				dependOnIds[conduit] = entity.associatedBarrierId
			GlobalDefinitions.EntityType.Lightning:
				var special = newSpecialAtPosition(entity.position, entity.type, entity.details)
				newIdMap[entity.idAtCreation] = special.idAtCreation
			_: # Upgrades
				newBenefitAtPosition(entity.position, entity.type)
				
	for entity in dependOnIds: # Fix outdated Id references
		var oldId = dependOnIds[entity]
		entity.associatedBarrierId = newIdMap[oldId]


func isSpaceAvailable(objectPosition: Vector2, radius: float) -> bool:
	# TODO: Since we approximate boxes as spheres this is a way too coarse approximation
	for entity in get_children():
		if entity.is_queued_for_deletion(): continue
		# Test intersection of bounding spheres
		var deltaPos = entity.center - objectPosition
		if deltaPos.length() < radius + entity.radius:
			# Now test intersection of bounding boxes
			if max(abs(deltaPos.x), abs(deltaPos.y)) < 0.5 * gridConstant - entity.margin + radius:
				return false
	return true


func calculateOnEntityCollision(ball, collisionEvent: Dictionary) -> void:
	var geometricCollisionData = calculateNextCollision(ball.position, ball.velocity, ball.debugMode)
	if geometricCollisionData["t"] < INF:
		GlobalDefinitions.updateCollisionEventFromGeometricData(
			collisionEvent, "Entity", geometricCollisionData
		)


func calculateNextCollision(objectPosition: Vector2, objectVelocity: Vector2, debugMode: bool = false) -> Dictionary:
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
		
		elif entity is Box:
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
				var collisionLocation = objectPosition + objectVelocity * tCollision
				GlobalDefinitions.updateGeometricCollision(
					geometricCollisionData, tCollision, entity.name + "-corner" + str(i), collisionLocation,
					objectVelocity.bounce((entity.polygon[i] - collisionLocation).normalized())
				)
		
		elif entity is SpecialNode:
			entity.calculateNextCollision(
				geometricCollisionData, objectPosition, objectVelocity, ballRadius
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
	
	elif collisionEvent["partner details"].contains("LightningBarrier"):
		specialHit.emit(ball, entity.type)
		return
	
	# Box destruction
	entity.applyDamage()
	boxHit.emit(ball)
	if entity.health <= 0:
		entity.queue_free()
		boxDestruction.emit(collisionEvent["partner details"], entity.initialHealth)
