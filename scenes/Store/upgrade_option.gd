extends PanelContainer


signal upgrade(identifier)

var identifier: String


func setAbility(title: String) -> void:
	%Ability.text = title


func setCost(cost: int) -> void:
	%Cost.text = str(cost)


func setLevel(level: int, levelMax: int) -> void:
	if levelMax == int(INF):
		%Progress.text = str(level) + " / -"
		return
	%Progress.text = str(level) + " / " + str(levelMax)


func setEffect(current, new):
	%CurrentValue.text = current
	%NextValue.text = new


func _on_texture_button_pressed() -> void:
	upgrade.emit(identifier)
