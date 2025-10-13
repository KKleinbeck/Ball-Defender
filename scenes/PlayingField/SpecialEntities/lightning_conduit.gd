extends Box


var associatedBarrierId: int


func _ready() -> void:
	type = GlobalDefinitions.EntityType.LightningConduit


func setup(_gridConstant: float, _margin: int, _start: Vector2, _health: int, _initialHealth: int) -> void:
	super(_gridConstant, _margin, _start, _health, _initialHealth)
	$TextureRect.size = gridConstant * Vector2(1., 1.)
	$TextureRect.position = _start


func walk() -> void:
	super()
	$TextureRect.position += gridConstant * Vector2.DOWN


func _notification(what):
	var barrier = instance_from_id(associatedBarrierId)
	if what == NOTIFICATION_PREDELETE and is_instance_valid(barrier):
		barrier.queue_free()
		# TODO: After destruction make sure that no balls have collisions with this barrier.
