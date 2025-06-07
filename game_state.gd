extends Node


enum Mode {SETUP, RUNNING, HALTING, GAMEOVER}
var mode: Mode = Mode.SETUP


var state: Dictionary = {"score": 0}
var gameStateLocation: String = "user://GameState.json"
var runningReloadedGame: bool = false


func reset() -> void:
	mode = Mode.SETUP
	state = {"score": 0}
	runningReloadedGame = false


func saveState() -> void:
	var file = FileAccess.open_encrypted_with_pass(gameStateLocation, FileAccess.WRITE, "AzcVVgc7P4amvfF9LNhrAtjdyxzhp5ze")
	file.store_var(state.duplicate())
	file.close()


func loadState() -> void:
	runningReloadedGame = true
	if FileAccess.file_exists(gameStateLocation):
		var file = FileAccess.open_encrypted_with_pass(gameStateLocation, FileAccess.READ, "AzcVVgc7P4amvfF9LNhrAtjdyxzhp5ze")
		state = file.get_var()
		file.close()


func eraseStoredState() -> void:
	runningReloadedGame = false
	var dir = DirAccess.open("user://")
	dir.remove(gameStateLocation)


func previousGameExists() -> bool:
	return FileAccess.file_exists(gameStateLocation)
