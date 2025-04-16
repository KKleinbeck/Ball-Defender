extends Control


signal readyAndRendered()
signal boxDestruction(details, scorePoints)
signal collectUpgrade(details, type)
signal gameover()


@export var boxes: PackedScene
@export var upgrades: PackedScene


enum BoxType {Empty, Standard, TimeUp}


var isReady: bool = false
var gameCanvas: Rect2
var gridConstant: int
var margin: int = 5
var upgradeMargin: int = 10
var boxesPerRow: int = 10
var nRows: int = 0
var pTimeUp: float = 0.1


func _process(_delta: float) -> void:
	gridConstant = int(size.x / boxesPerRow)
	readyAndRendered.emit()
	set_process(false)


func reset() -> void:
	nRows = 0
	for box in get_children():
		box.queue_free()


func newBoxAtColumnRow(x: int, y: int) -> Polygon2D:
	var start = position + gridConstant * Vector2(x, y)
	
	var box = boxes.instantiate()
	var health = nRows - randi_range(0, 1) * int(nRows / 2.)
	box.setup(gridConstant, margin, start, health)
	add_child(box)
	return box


func newTimeUpAtColumnRow(x: int, y: int) -> TextureRect:
	var start = position + gridConstant * Vector2(x, y)
	
	var upgrade = upgrades.instantiate()
	upgrade.makeTimeUp(gridConstant, upgradeMargin, start)
	add_child(upgrade)
	return upgrade


func newRow() -> void:
	nRows += 1
	
	# Determining number and location of boxes
	var nBoxes = randi_range(3, 6)
	
	var boxLocation = []
	for n in boxesPerRow:
		if n < nBoxes:
			boxLocation.append(BoxType.Standard)
		else:
			boxLocation.append(BoxType.Empty)
	if randf() < pTimeUp:
		boxLocation[-1] = BoxType.TimeUp
	boxLocation.shuffle()
	
	for n in boxesPerRow:
		match boxLocation[n]:
			BoxType.Standard:
				newBoxAtColumnRow(n, 0)
			BoxType.TimeUp:
				newTimeUpAtColumnRow(n, 0)
			_:
				pass


func walk() -> void:
	for box in get_children():
		if box is Polygon2D and box.polygon[3].y + gridConstant > size.y:
			gameover.emit()
			return
		box.walk()
	newRow()


func calculateOnBoxCollision(ball, collisionEvent: Dictionary) -> void:
	var trajDir = ball.velocity.normalized()
	var boxWidth = gridConstant - 2 * margin
	var radius = 0.5 * ball.diameter
	var cornerCollDist = sqrt(1/2.) * boxWidth + radius
	var wallCollDist = 0.5 * (boxWidth + ball.diameter)
	
	for box in get_children():
		if box.is_queued_for_deletion(): continue
		
		if box is TextureRect:
			var center = box.position + 0.5 * boxWidth * Vector2(1., 1.)
			var deltaPos = center - ball.position
			
			var signedLongDist = deltaPos.dot(trajDir)
			var signedOrthoDist = deltaPos.cross(trajDir)
			var distAtCollision = box.radius + radius
			if signedLongDist < 0 or abs(signedOrthoDist) > distAtCollision:
				continue
				
			var travelDist = signedLongDist - sqrt(distAtCollision * distAtCollision - signedOrthoDist * signedOrthoDist)
			var tCollision = travelDist / ball.velocity.length()
			if tCollision < 0: continue
			GlobalDefinitions.updateCollisionEvent(
				collisionEvent, tCollision, "Entity", box.name + "-" + "upgrade",
				center - 0.99 * distAtCollision * trajDir.rotated(asin(-signedOrthoDist / distAtCollision))
			)
		
		if box is Polygon2D:
			var deltaPos = box.polygon[0] - ball.position + 0.5 * boxWidth * Vector2(1., 1.)
			
			# check if ball traveling towards box and box within potential collision range
			if deltaPos.dot(trajDir) < 0 or abs(deltaPos.cross(trajDir)) > cornerCollDist:
				if ball.debugMode: box.color = Color(1, 1, 1)
				continue
			else:
				if ball.debugMode: box.color = Color(1, 0, 0)
				
				# side wall collision
				var horDist = deltaPos.x - sign(trajDir.x) * wallCollDist
				if sign(trajDir.x) * horDist > 0:
					var tCollision = horDist / ball.velocity.x
					if abs(deltaPos.y - ball.velocity.y * tCollision) < 0.5 * boxWidth:
						if ball.debugMode: box.color = Color(0, 0, 1.)
						GlobalDefinitions.updateCollisionEvent(
							collisionEvent, tCollision, "Entity", box.name + "-" + "horizontal",
							Vector2(
								box.polygon[1 - sign(trajDir.x)].x - radius * sign(trajDir.x),
								ball.position.y + ball.velocity.y * tCollision
							)
						)
						
				var vertDist = deltaPos.y - sign(trajDir.y) * wallCollDist
				if sign(trajDir.y) * vertDist > 0:
					var tCollision = vertDist / ball.velocity.y
					if abs(deltaPos.x - ball.velocity.x * tCollision) < 0.5 * boxWidth:
						if ball.debugMode: box.color = Color(0, 0, 1.)
						GlobalDefinitions.updateCollisionEvent(
							collisionEvent, tCollision, "Entity", box.name + "-" + "vertical",
							Vector2(
								ball.position.x + ball.velocity.x * tCollision,
								box.polygon[1 - sign(trajDir.y)].y - radius * sign(trajDir.y)
							)
						)
				
				# Corner collision
				for i in 4:
					var cornerToBall = box.polygon[i] - ball.position
					var signedOrthoDist = cornerToBall.cross(trajDir)
					if abs(signedOrthoDist) > radius: continue
					var travelDist = cornerToBall.dot(trajDir) - sqrt(radius * radius - signedOrthoDist * signedOrthoDist)
					var tCollision = travelDist / ball.velocity.length()
					if tCollision < 0: continue
					if ball.debugMode: box.color = Color(0, 0, 1.)
					GlobalDefinitions.updateCollisionEvent(
						collisionEvent, tCollision, "Entity", box.name + "-" + "corner" + str(i),
						box.polygon[i] - 0.99 * radius * trajDir.rotated(asin(-signedOrthoDist / radius))
					)


func resolveOnBoxCollision(collisionEvent: Dictionary) -> void:
	var ball = collisionEvent["ball"]
	var boxName = collisionEvent["partner details"].split("-")[0]
	var box = get_children().filter(func(x): return x.name == boxName)[0]
	
	# Collision Physics
	if collisionEvent["partner details"].contains("horizontal"):
		ball.velocity.x *= -1
	elif collisionEvent["partner details"].contains("vertical"):
		ball.velocity.y *= -1
	elif collisionEvent["partner details"].contains("corner"):
		var corner = box.polygon[int(collisionEvent["partner details"][-1])]
		ball.velocity = ball.velocity.bounce((corner - ball.position).normalized())
	elif collisionEvent["partner details"].contains("upgrade"):
		box.queue_free()
		collectUpgrade.emit(collisionEvent["partner details"], box.type)
		return
	# TODO: After all stability improvements, we should still implement a check here, to see whether the ball entered a box at this step
	
	# Box destruction
	box.changeHealth(-1)
	if box.health <= 0:
		box.queue_free()
		boxDestruction.emit(collisionEvent["partner details"], box.initialHealth)
