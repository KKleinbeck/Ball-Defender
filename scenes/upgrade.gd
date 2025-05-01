extends TextureRect


var gridConstant: int
var margin: int
var radius: float
var center: Vector2
var type: GlobalDefinitions.EntityType

var upgradeMargin = {
	GlobalDefinitions.EntityType.Damage: 10,
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
	radius = 0.5 * gridConstant - margin # Fictitious radius - circle fully _within_ texture
	type = _type
	
	match type:
		GlobalDefinitions.EntityType.Damage:
			texture = load("res://assets/upgrades/damage.png")
		GlobalDefinitions.EntityType.TimeUp:
			texture = load("res://assets/upgrades/timer.png")
		GlobalDefinitions.EntityType.Currency:
			texture = load("res://assets/upgrades/currency.png")
		GlobalDefinitions.EntityType.PremiumCurrency:
			texture = load("res://assets/upgrades/premiumCurrency.png")
		GlobalDefinitions.EntityType.Charge:
			texture = load("res://assets/upgrades/charge.png")
		_:
			pass
	
	position = start + Vector2(margin, margin)
	center = start + 0.5 * gridConstant * Vector2(1., 1.)
	size = Vector2(gridConstant - 2*margin, gridConstant - 2*margin)


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	center += yDown
	position += yDown
