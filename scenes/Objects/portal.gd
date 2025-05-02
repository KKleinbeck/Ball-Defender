extends TextureRect


var rotationSpeed: float = 1.


func _process(delta: float) -> void:
	rotation += rotationSpeed * delta


func setup(_position: Vector2, _size: Vector2):
	position = _position - 0.5 * _size
	size = _size
	pivot_offset = 0.5 * _size
