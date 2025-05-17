extends Node


@onready var admob: Admob = $Admob
var runningScene: Node


func _ready() -> void:
	admob.initialize()
	GlobalDefinitions.globalChannel.connect(_on_global_msg)
	
	runningScene = load("res://scenes/main_menu.tscn").instantiate()
	runningScene.changeGameScene.connect(_on_change_game_scene)
	add_child(runningScene)


func _on_global_msg(msg: String) -> void:
	$Label.text = msg


func _on_admob_initialised(_status_data: InitializationStatus) -> void:
	$Label.text = "Admob Initialised"
	GlobalDefinitions.admobInitilised = true


func _on_admob_rewarded_ad_loaded(ad_id: String) -> void:
	$Label.text = "Reward Ad Ready: " + ad_id
	admob.show_rewarded_ad()
	runningScene._on_rewarded()


func _on_change_game_scene(sceneName: String) -> void:
	runningScene.queue_free()
	
	match sceneName:
		"EndlessMode":
			runningScene = load("res://scenes/endless_mode.tscn").instantiate()
		
		"Store":
			runningScene = load("res://scenes/store.tscn").instantiate()
			
		"MainMenu", _:
			runningScene = load("res://scenes/main_menu.tscn").instantiate()
	
	runningScene.changeGameScene.connect(_on_change_game_scene)
	for signalCandidate in runningScene.get_signal_list():
		if signalCandidate.name == "showRewardAd":
			runningScene.showRewardAd.connect(_on_show_reward_ad)
			break
	add_child(runningScene)


func _on_show_reward_ad() -> void:
	admob.load_rewarded_ad()
	# TODO: Implement timer here and send failure signal if loading fails
	
