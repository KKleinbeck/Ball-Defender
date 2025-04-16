extends Node


enum Upgrade {TimeUp}

enum State {RUNNING, HALTING, GAMEOVER}
var state: State = State.RUNNING


func _ready() -> void:
	set_process(false)
