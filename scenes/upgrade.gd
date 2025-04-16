extends TextureRect


var gridConstant: int
var margin: int
var radius: float
var type: GlobalDefinitions.Upgrade


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)


func makeTimeUp(_gridConstant: int, _margin: int, start: Vector2) -> void:
	texture = load("res://assets/timer.png")
	type = GlobalDefinitions.Upgrade.TimeUp
	gridConstant = _gridConstant
	margin = _margin
	radius = 0.5 * gridConstant - _margin
	
	position = start + Vector2(margin, margin)
	size = Vector2(gridConstant - 2*margin, gridConstant - 2*margin)


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	position += yDown
