extends Control


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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
