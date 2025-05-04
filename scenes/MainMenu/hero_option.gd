extends MarginContainer


signal pressed(hero: String)


@export var title: String :
	get:
		return title
	set(value):
		title = value
		%Title.text = value


func _ready() -> void:
	set_process(false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed.emit(title)


func setAbility(n: int, ability: String) -> void:
	get_node("%Image" + str(n)).texture = load("res://assets/abilities/Option" + ability + ".png")
	get_node("%ImageSubtitle" + str(n)).text = ability


func setToEndOfList() -> void:
	add_theme_constant_override("margin_bottom", 0)
