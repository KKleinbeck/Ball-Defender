extends CanvasLayer


signal continueGame
signal restartGame
signal endGame


func hideContinue():
	%PanelContinue.hide()


func showContinue():
	%PanelContinue.show()


func setRewardAmount(amount: int) -> void:
	%Amount.text = "+ " + str(amount)


func _on_continue_pressed() -> void:
	continueGame.emit()


func _on_restart_pressed() -> void:
	restartGame.emit()


func _on_end_pressed() -> void:
	endGame.emit()
