extends Polygon2D


const type = GlobalDefinitions.EntityType.Box


var initialHealth: int
var health: int
var gridConstant: float
var margin: int
var radius: float
var center: Vector2


func setup(_gridConstant: float, _margin: int, _start: Vector2, _health: int, _initialHealth: int) -> void:
	gridConstant = _gridConstant
	margin = _margin
	radius = sqrt(1/2.) * (gridConstant - 2 * margin) # Fictitious radius - circle _engulfing_ box
	initialHealth = _initialHealth
	health = _health
	$Label.text = str(health)
	$Label.size = gridConstant * Vector2(1., 1.)
	$Label.position = _start
	
	var start = _start + Vector2(margin, margin)
	center = _start + 0.5 * gridConstant * Vector2(1., 1.)
	polygon = PackedVector2Array([
		start,
		start + (gridConstant - 2*margin) * Vector2(1., 0.),
		start + (gridConstant - 2*margin) * Vector2(1., 1.),
		start + (gridConstant - 2*margin) * Vector2(0., 1.)
	])


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	center += yDown
	for i in 4: polygon[i] += yDown
	$Label.position += yDown


func applyDamage() -> void:
	var damage = Player.getUpgrade("damage")
	var fullDamage = int(damage)
	if randf() < damage - fullDamage:
		fullDamage += 1
	health -= fullDamage
	$Label.text = str(health)
