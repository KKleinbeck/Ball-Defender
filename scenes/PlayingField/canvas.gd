extends ColorRect


signal cursorDragStart(start: Vector2)
signal cursorReleased(start: Vector2, end: Vector2)


var pressReadied: bool = false
var pressStartLocation: Vector2


func _input(event: InputEvent) -> void:
	if Player.state.isDrawing: return
	
	var clickLocation = get_local_mouse_position()
	if event is InputEventMouseButton and event.pressed:
		if !pressReadied:
			pressStartLocation = clickLocation
		cursorDragStart.emit(pressStartLocation)
		pressReadied = true
	
	if event is InputEventMouseButton and event.pressed == false and pressReadied: # pressed == false => mouse up
		pressReadied = false
		# Ignore clicks outside the field or too distant locations
		if clickLocation.y < position.y or clickLocation.y > position.y + size.y or \
		   ( (clickLocation - pressStartLocation).length() > 20 and Player.state.doNotStartOnDrag):
			return
		cursorReleased.emit(pressStartLocation, clickLocation)


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
