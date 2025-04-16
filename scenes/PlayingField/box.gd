extends Polygon2D


var initialHealth: int
var health: int
var gridConstant: float
var margin: int
var start: Vector2


func setup(_gridConstant: float, _margin: int, _start: Vector2, _health: int) -> void:
	gridConstant = _gridConstant
	margin = _margin
	initialHealth = _health
	health = _health
	$Label.text = str(health)
	$Label.size = gridConstant * Vector2(1., 1.)
	$Label.position = _start
	
	start = _start + Vector2(margin, margin)
	polygon = PackedVector2Array([
		start,
		start + (gridConstant - 2*margin) * Vector2(1., 0.),
		start + (gridConstant - 2*margin) * Vector2(1., 1.),
		start + (gridConstant - 2*margin) * Vector2(0., 1.)
	])


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	for i in 4: polygon[i] += yDown
	$Label.position += yDown


func changeHealth(delta) -> void:
	health += delta
	$Label.text = str(health)
