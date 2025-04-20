extends MarginContainer


signal upgrade(identifier)

var identifier: String


func setTitle(title: String) -> void:
	%Title.text = title


func setCost(cost: int) -> void:
	%Cost.text = str(cost)


func setLevel(level: int) -> void:
	%Level.text = str(level)


func setEffect(current, new):
	%Current.text = current
	%New.text = new


func _on_texture_rect_pressed() -> void:
	upgrade.emit(identifier)
