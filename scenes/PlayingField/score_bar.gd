extends PanelContainer


func setBallNumber(n: int) -> void:
	%NumberBalls.text = str(n)


func setDeathTimer(n: int) -> void:
	%DeathTimer.text = str(n)


func setDamage(d: float) -> void:
	var n = int(d)
	var p = int((d - n + 0.001) * 100)
	if p == 0:
		%Damage.text = str(n)
	else:
		%Damage.text = str(n) + " + " + str(p) + "%"


func setScore(n: int) -> void:
	%Score.text = str(n)
