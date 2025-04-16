extends PanelContainer


func setBallNumber(n: int) -> void:
	%NumberBalls.text = str(n)


func setDeathTimer(n: int) -> void:
	%DeathTimer.text = str(n)


func setScore(n: int) -> void:
	%Score.text = str(n)
