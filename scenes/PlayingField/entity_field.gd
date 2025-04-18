extends Control


signal readyAndRendered()
signal boxDestruction(details, scorePoints)
signal collectUpgrade(details, type)
signal gameover()


@export var boxes: PackedScene
@export var upgrades: PackedScene


var isReady: bool = false
var gameCanvas: Rect2
var gridConstant: int
var margin: int = 5
var boxesPerRow: int = 9
var nRows: int = 0


func _process(_delta: float) -> void:
	gridConstant = int(size.x / boxesPerRow)
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
	for n in boxesPerRow:
		if n < nBoxes:
			boxLocation.append(GlobalDefinitions.EntityType.Standard)
		else:
			boxLocation.append(GlobalDefinitions.EntityType.Empty)
	if randf() < Player.upgrades["pDeathTime"]:
		boxLocation[-2] = GlobalDefinitions.EntityType.TimeUp
	if randf() < chanceCurrency("Currency"):
		boxLocation[-1] = GlobalDefinitions.EntityType.Currency
	elif randf() < chanceCurrency("PremiumCurrency"): # Do not spawn currency and and premium at the same time
		boxLocation[-1] = GlobalDefinitions.EntityType.PremiumCurrency
	boxLocation.shuffle()
	
	for n in boxesPerRow:
		match boxLocation[n]:
			GlobalDefinitions.EntityType.Empty:
				continue
			GlobalDefinitions.EntityType.Standard:
				newBoxAtColumnRow(n, 0)
			_:
				newBenefitAtColumnRow(n, 0, boxLocation[n])


func chanceCurrency(type: String) -> float:
	var p0 = Player.upgrades["p" + type]
	var pinf = Player.upgrades["p" + type + "Eventually"]
	return pinf + (p0 - pinf) / (1. + (nRows - 1.) / 50.)


func walk() -> void:
	for entity in get_children():
		if (entity is Polygon2D and entity.polygon[3].y + 1.5 * gridConstant > size.y) or \
		   entity.position.y + gridConstant > size.y:
			gameover.emit()
			return
		entity.walk()
	newRow()


func calculateOnBoxCollision(ball, collisionEvent: Dictionary) -> void:
	var trajDir = ball.velocity.normalized()
	var boxWidth = gridConstant - 2 * margin
	var radius = 0.5 * ball.diameter
	var cornerCollDist = sqrt(1/2.) * boxWidth + radius
	var wallCollDist = 0.5 * (boxWidth + ball.diameter)
	
	for entity in get_children():
		if entity.is_queued_for_deletion(): continue
		
		if entity is TextureRect:
			var center = entity.position + 0.5 * boxWidth * Vector2(1., 1.)
			var deltaPos = center - ball.position
			
			var signedLongDist = deltaPos.dot(trajDir)
			var signedOrthoDist = deltaPos.cross(trajDir)
			var distAtCollision = entity.radius + radius
			if signedLongDist < 0 or abs(signedOrthoDist) > distAtCollision:
				continue
				
			var travelDist = signedLongDist - sqrt(distAtCollision * distAtCollision - signedOrthoDist * signedOrthoDist)
			var tCollision = travelDist / ball.velocity.length()
			if tCollision < 0: continue
			GlobalDefinitions.updateCollisionEvent(
				collisionEvent, tCollision, "Entity", entity.name + "-" + "upgrade",
				center - 0.99 * distAtCollision * trajDir.rotated(asin(-signedOrthoDist / distAtCollision))
			)
		
		if entity is Polygon2D:
			var deltaPos = entity.polygon[0] - ball.position + 0.5 * boxWidth * Vector2(1., 1.)
			
			# check if ball traveling towards box and box within potential collision range
			if deltaPos.dot(trajDir) < 0 or abs(deltaPos.cross(trajDir)) > cornerCollDist:
				if ball.debugMode: entity.color = Color(1, 1, 1)
				continue
			else:
				if ball.debugMode: entity.color = Color(1, 0, 0)
				
				# side wall collision
				var horDist = deltaPos.x - sign(trajDir.x) * wallCollDist
				if sign(trajDir.x) * horDist > 0:
					var tCollision = horDist / ball.velocity.x
					if abs(deltaPos.y - ball.velocity.y * tCollision) < 0.5 * boxWidth:
						if ball.debugMode: entity.color = Color(0, 0, 1.)
						GlobalDefinitions.updateCollisionEvent(
							collisionEvent, tCollision, "Entity", entity.name + "-" + "horizontal",
							Vector2(
								entity.polygon[1 - sign(trajDir.x)].x - radius * sign(trajDir.x),
								ball.position.y + ball.velocity.y * tCollision
							)
						)
						
				var vertDist = deltaPos.y - sign(trajDir.y) * wallCollDist
				if sign(trajDir.y) * vertDist > 0:
					var tCollision = vertDist / ball.velocity.y
					if abs(deltaPos.x - ball.velocity.x * tCollision) < 0.5 * boxWidth:
						if ball.debugMode: entity.color = Color(0, 0, 1.)
						GlobalDefinitions.updateCollisionEvent(
							collisionEvent, tCollision, "Entity", entity.name + "-" + "vertical",
							Vector2(
								ball.position.x + ball.velocity.x * tCollision,
								entity.polygon[1 - sign(trajDir.y)].y - radius * sign(trajDir.y)
							)
						)
				
				# Corner collision
				for i in 4:
					var cornerToBall = entity.polygon[i] - ball.position
					var signedOrthoDist = cornerToBall.cross(trajDir)
					if abs(signedOrthoDist) > radius: continue
					var travelDist = cornerToBall.dot(trajDir) - sqrt(radius * radius - signedOrthoDist * signedOrthoDist)
					var tCollision = travelDist / ball.velocity.length()
					if tCollision < 0: continue
					if ball.debugMode: entity.color = Color(0, 0, 1.)
					GlobalDefinitions.updateCollisionEvent(
						collisionEvent, tCollision, "Entity", entity.name + "-" + "corner" + str(i),
						entity.polygon[i] - 0.999 * radius * trajDir.rotated(asin(-signedOrthoDist / radius))
					)


func resolveOnBoxCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	var boxName = collisionEvent["partner details"].split("-")[0]
	var entity = get_children().filter(func(x): return x.name == boxName)[0]
	
	# Collision Physics
	if collisionEvent["partner details"].contains("horizontal"):
		ball.velocity.x *= -1
	elif collisionEvent["partner details"].contains("vertical"):
		ball.velocity.y *= -1
	elif collisionEvent["partner details"].contains("corner"):
		var corner = entity.polygon[int(collisionEvent["partner details"][-1])]
		ball.velocity = ball.velocity.bounce((corner - ball.position).normalized())
	elif collisionEvent["partner details"].contains("upgrade"):
		entity.queue_free()
		collectUpgrade.emit(collisionEvent["partner details"], entity.type)
		return
	# TODO: After all stability improvements, we should still implement a check here, to see whether the ball entered a box at this step
	
	# Box destruction
	entity.applyDamage()
	if entity.health <= 0:
		entity.queue_free()
		boxDestruction.emit(collisionEvent["partner details"], entity.initialHealth)
