extends Node2D


@export var diameter = 20.
@export var mass = 1.
var velocity = Vector2.ZERO
var color: Color = Color.WHITE

var debugMode: bool = false


func _draw() -> void:
	draw_circle(Vector2(0, 0), diameter / 2., color)


func propagate(delta: float) -> void:
	position += velocity * delta
	if AbilityDefinitions.factory["AntiGravity"].active == true:
		velocity.y -= 300 * delta
		CollisionList.triggerUpdateFor(self)


func toggleDebug() -> void:
	debugMode = !debugMode
	if debugMode:
		color = Color.RED
	else:
		color = Color.WHITE
	queue_redraw()
