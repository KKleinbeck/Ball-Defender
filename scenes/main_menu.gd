extends Node


signal changeGameScene(id: String)


func _ready() -> void:
	for _i in 5:
		spawnRandomBall()
	
	TranslationServer.set_locale(OS.get_locale_language())
	
	%OptionEndless.pressed.connect(_on_endless_start)
	%OptionDaily.pressed.connect(_debug_info)
	%OptionUpgrades.pressed.connect(_enter_upgrade_store)
	%OptionSettings.pressed.connect(spawnRandomBall)
	
	%OptionEndless.subtitle = "Highscore"
	%OptionEndless.addendum = str(Player.state["highscore"])
	
	%OptionUpgrades.subtitle = str(Player.state["currency"]["standard"])
	%OptionUpgrades.setImage1("res://assets/upgrades/currency.png")
	%OptionUpgrades.addendum = str(Player.state["currency"]["premium"])
	%OptionUpgrades.setImage2("res://assets/upgrades/premiumCurrency.png")


func spawnRandomBall() -> void:
	var position = Vector2(
		randi_range(%PlayingField.position.x + 20, %PlayingField.size.x - 20),
		randi_range(%PlayingField.position.y + 20, %PlayingField.size.y - 20)
	)
	$PlayingField.spawnBall(position, 100 * Vector2.UP.rotated(2 * PI * randf()))


func showHeroSelect() -> void:
	$HeroContainer.modulate.a = 0
	$HeroContainer.show()
	
	# Animate transition
	var tween = get_tree().create_tween()
	tween.tween_property($HeroContainer, "modulate", Color(1, 1, 1, 1), 0.4)
	tween.parallel().tween_property($Options, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_property($Options, "visible", false, 0.4)
	
	var n = 0
	for hero in Player.state.heros:
		n += 1
		var option = load("res://scenes/MainMenu/HeroOption.tscn").instantiate()
		option.title = hero
		option.pressed.connect(heroSelected)
		if n == Player.state.heros.size():
			option.margin_bottom = 0
		
		for m in Player.state.heros[hero].size():
			var ability = Player.state.heros[hero][m]
			option.setAbility(m+1, ability)
		%HeroOptions.add_child(option)


func heroSelected(hero) -> void:
	for n in Player.state.heros[hero].size():
		var ability = Player.state.heros[hero][n]
		
		if n == 0:
			Player.abilities.MainAbility.id = ability
		else:
			Player.abilities["Ability" + str(n)].id = ability
	
	CollisionList.reset()
	changeGameScene.emit("EndlessMode")


# ========================================
# ========= Collision Handling ===========
# ========================================
func _on_playing_field_ball_despawned() -> void:
	spawnRandomBall()


func _on_endless_start() -> void:
	showHeroSelect()


func _enter_upgrade_store() -> void:
	CollisionList.reset()
	changeGameScene.emit("Store")


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
