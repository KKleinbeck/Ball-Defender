extends CanvasLayer


signal continueGame
signal restartGame
signal endGame


func hideContinue():
	%MarginContinue.hide()


func _on_continue_pressed() -> void:
	continueGame.emit()


func _on_restart_pressed() -> void:
	restartGame.emit()


func _on_end_pressed() -> void:
	endGame.emit()
