extends MarginContainer


signal pressed(hero: String)


@export var margin_bottom: int = 25


@export var title: String :
	get:
		return title
	set(value):
		title = value
		%Title.text = "HERO_" + value.to_upper()
		%HeroIcon.texture = load("res://assets/UI/" + value + ".png")


func _ready() -> void:
	add_theme_constant_override("margin_bottom", margin_bottom)
	set_process(false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed.emit(title)


func setAbility(n: int, ability: String) -> void:
	get_node("%Image" + str(n)).texture = load("res://assets/abilities/Option" + ability + ".png")
	get_node("%ImageSubtitle" + str(n)).text = ability
