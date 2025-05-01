extends Node


func travelDist(longDistance: float, orthoDistance: float, distanceAtCollision: float) -> float:
	return longDistance - sqrt(distanceAtCollision * distanceAtCollision - orthoDistance * orthoDistance)


func totalLength(arrays: PackedVector2Array) -> float:
	var result = 0.
	for n in arrays.size() - 1:
		if arrays[n] == Vector2.INF or arrays[n+1] == Vector2.INF: continue
		result += (arrays[n+1] - arrays[n]).length()
	return result


func pointAtDistance(targetDistance: float, arrays: PackedVector2Array) -> Vector2:
	for n in arrays.size() - 1:
		if arrays[n] == Vector2.INF or arrays[n+1] == Vector2.INF: continue
		var direction = arrays[n+1] - arrays[n]
		if direction.length() < targetDistance:
			targetDistance -= direction.length()
			continue
		return targetDistance * direction.normalized() + arrays[n]
	return arrays[arrays.size() - 1]
