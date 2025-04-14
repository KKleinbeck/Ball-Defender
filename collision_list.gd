extends Node


signal requestCollisionUpdate()


var entries: Array = []


func isEmpty() -> bool:
	return entries.size() == 0


func last() -> Dictionary:
	return entries[-1]


func pop_back() -> void:
	entries.pop_back()


func reset() -> void:
	entries = []


func add(collisionEvent: Dictionary) -> void:
	for collision in entries:
		if collision["ball"].name == collisionEvent["ball"].name:
			push_error("Duplicate names in collision list when adding event:\n\t" + str(collisionEvent))
	var index = 0
	for others in entries:
		if others["t"] < collisionEvent["t"]:
			break
		index += 1
	entries.insert(index, collisionEvent)


func removeBall(ball: Node) -> void:
	var eliminationSet = {}
	recursiveRemoveBallDependencies(ball, eliminationSet)
	for deletedBall in eliminationSet:
		requestCollisionUpdate.emit(deletedBall)


func recursiveRemoveBallDependencies(ball: Node, eliminationSet: Dictionary) -> void:
	var index = 0
	for collisionEvent in entries:
		if collisionEvent["ball"] == ball:
			entries.remove_at(index)
			eliminationSet[ball] = null
			#recursiveRemoveBallDependencies(ball, eliminationSet)
			#return
		if collisionEvent["partner"] == "Ball":
			entries.remove_at(index)
			eliminationSet[collisionEvent["ball"]] = null
			recursiveRemoveBallDependencies(collisionEvent["ball"], eliminationSet)
			#return
		index += 1
