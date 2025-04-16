extends Panel


func setTitle(title: String) -> void:
	$Title.text = title


func setCost(cost: int) -> void:
	$Cost.text = str(cost)


func setLevel(level: int) -> void:
	$Level.text = str(level)
