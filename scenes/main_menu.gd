extends Node


func _ready() -> void:
	for _i in 5:
		spawnRandomBall()


func spawnRandomBall() -> void:
	var position = Vector2(
		randi_range(0, %Background.size.x),
		randi_range(0, %Background.size.y)
	)
	$PlayingField.spawnBall(position, 100 * Vector2.UP.rotated(2 * PI * randf()))


func _on_playing_field_ball_despawned() -> void:
	spawnRandomBall()
