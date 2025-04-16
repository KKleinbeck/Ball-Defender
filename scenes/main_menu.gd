extends Node


func _ready() -> void:
	for _i in 5:
		spawnRandomBall()
	
	%OptionEndless.pressed.connect(_on_endless_start)
	%OptionDaily.pressed.connect(_debug_info)
	%OptionUpgrades.pressed.connect(_enter_upgrade_store)
	%OptionSettings.pressed.connect(spawnRandomBall)


func spawnRandomBall() -> void:
	var position = Vector2(
		randi_range(%PlayingField.position.x + 20, %PlayingField.size.x - 20),
		randi_range(%PlayingField.position.y + 20, %PlayingField.size.y - 20)
	)
	$PlayingField.spawnBall(position, 100 * Vector2.UP.rotated(2 * PI * randf()))


# ========================================
# ========= Collision Handling ===========
# ========================================
func _on_playing_field_ball_despawned() -> void:
	spawnRandomBall()


func _on_endless_start() -> void:
	CollisionList.purge()
	get_tree().change_scene_to_file("res://scenes/endless_mode.tscn")


func _enter_upgrade_store() -> void:
	CollisionList.purge()
	get_tree().change_scene_to_file("res://scenes/store.tscn")


func _debug_info() -> void:
	print("=========================")
	var t = INF
	for entry in CollisionList.entries:
		print(entry["t"])
		if entry["t"] <= t:
			t = entry["t"]
		else:
			print("Unsorted!")
			return
	print("Sorted")
	print("Lost Balls: ", %PlayingField.ballDict.size() - CollisionList.entries.size())
