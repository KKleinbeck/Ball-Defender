extends TextureRect


var gridConstant: int
var margin: int
var radius: float
var type: GlobalDefinitions.EntityType

var upgradeMargin = {
	GlobalDefinitions.EntityType.TimeUp: 10,
	GlobalDefinitions.EntityType.Currency: 15,
	GlobalDefinitions.EntityType.PremiumCurrency: 15,
	GlobalDefinitions.EntityType.Charge: 10
}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)


func createBenefit(_gridConstant: int, start: Vector2, _type: GlobalDefinitions.EntityType) -> void:
	gridConstant = _gridConstant
	margin = upgradeMargin[_type]
	radius = 0.5 * gridConstant - margin
	type = _type
	
	match type:
		GlobalDefinitions.EntityType.TimeUp:
			texture = load("res://assets/timer.png")
		GlobalDefinitions.EntityType.Currency:
			texture = load("res://assets/currency.png")
		GlobalDefinitions.EntityType.PremiumCurrency:
			texture = load("res://assets/premiumCurrency.png")
		GlobalDefinitions.EntityType.Charge:
			texture = load("res://assets/charge.png")
		_:
			pass
	
	position = start + Vector2(margin, margin)
	size = Vector2(gridConstant - 2*margin, gridConstant - 2*margin)


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	position += yDown
