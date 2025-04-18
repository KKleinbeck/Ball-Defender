extends Container


signal pressed()


@export var title: String :
	get:
		return title
	set(value):
		title = value
		%Title.text = value

@export var subtitle: String :
	get:
		return subtitle
	set(value):
		subtitle = value
		%Subtitle.text = value
		
@export var addendum: String :
	get:
		return addendum
	set(value):
		addendum = value
		%Addendum.text = value


func _ready() -> void:
	set_process(false)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed.emit()


func setImage1(path: String) -> void:
	%Image1.texture = load(path)
	%Spacer.show()


func setImage2(path: String) -> void:
	%Image2.texture = load(path)
