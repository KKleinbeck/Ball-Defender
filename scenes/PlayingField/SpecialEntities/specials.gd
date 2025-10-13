class_name SpecialNode extends Node2D

var lightningScene = load("res://scenes/PlayingField/SpecialEntities/lightning_barrier.tscn")

var gridConstant: int
var radius: float
var center: Vector2
var details: Dictionary
var type: GlobalDefinitions.EntityType

var idAtCreation: int


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	idAtCreation = get_instance_id()


func create(_gridConstant: int, start: Vector2, _type: GlobalDefinitions.EntityType, _details: Dictionary) -> void:
	gridConstant = _gridConstant
	position = start
	details = _details
	type = _type
	if "width" in details:
		center = start + 0.5 * Vector2(details["width"], gridConstant)
		radius = 0.5 * details["width"]
	else:
		center = start + 0.5 * gridConstant * Vector2(1., 1.)
		radius = 0.5 * gridConstant
	
	if type == GlobalDefinitions.EntityType.Lightning:
		var lightningInstance = lightningScene.instantiate()
		lightningInstance.size.x = details["width"]
		lightningInstance.size.y = gridConstant
		add_child(lightningInstance)


func walk() -> void:
	var yDown = gridConstant * Vector2.DOWN
	center += yDown
	position += yDown


func calculateNextCollision(geometricCollisionData: Dictionary, p: Vector2, v: Vector2, r: float) -> void:
	if type == GlobalDefinitions.EntityType.Lightning:
		var tCollision = 0.
		if v.y < 0:
			tCollision = (position.y + gridConstant - 2*r - p.y) / v.y
		else:
			tCollision = (position.y + 2*r - p.y) / (v.y + 1e-200)
		GlobalDefinitions.updateGeometricCollision(
			geometricCollisionData, tCollision, name + "-LightningBarrier", p + v * tCollision, Vector2.ZERO
		)
