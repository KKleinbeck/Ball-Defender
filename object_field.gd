extends Control


signal requestLaserTrace(start: Vector2, direction: Vector2)


const laserDotDistance: float = 25.


var laserPointerActive: bool = false
var laserPointerStart: Vector2
var laserPointerPoints: PackedVector2Array
var phase: float = 0


# ========================================
# ========= Godot Overrides ==============
# ========================================
func _ready() -> void:
	AbilityDefinitions.laserPointerDeactivated.connect(deactivateLaserPointer)


func _process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var cursorLocation = get_local_mouse_position()
		var direction = (cursorLocation - laserPointerStart).normalized()
		var start = laserPointerStart + 20 * direction
		requestLaserTrace.emit(start, direction)
		print(laserPointerPoints)
		
		phase += 15 * delta
		if phase > laserDotDistance: phase -= laserDotDistance
		queue_redraw()


func _draw():
	if AbilityDefinitions.factory.LaserPointer.active and laserPointerPoints.size() > 1:
		var distance = Math.totalLength(laserPointerPoints) - phase
		if distance > 0:
			for n in int(distance / laserDotDistance) + 1:
				draw_circle(
					Math.pointAtDistance(n * laserDotDistance + phase, laserPointerPoints),
					4., Color.WHITE, true, -1.0, true
				)
		#for n in range(1, laserPointerPoints.size() - 1):
			#draw_line(laserPointerPoints[n], laserPointerPoints[n+1], Color.WHITE)
		#draw_polyline(laserPointerPoints, Color.WHITE, 2.0, true)


# ========================================
# ========= Custom Methods ===============
# ========================================
func deactivateLaserPointer() -> void:
	queue_redraw()
