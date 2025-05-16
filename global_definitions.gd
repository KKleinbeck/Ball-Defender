extends Node


signal globalChannel(msg: String)


const ballRadius: float = 10.
const boxesPerRow: int = 10


enum EntityType {Empty, Standard, Damage, TimeUp, Currency, PremiumCurrency, Charge}
enum State {RUNNING, HALTING, GAMEOVER}
var state: State = State.RUNNING

var admobInitilised: bool = false # set from entry


func _ready() -> void:
	set_process(false)


func updateCollisionEvent(collisionEvent: Dictionary, t: float, partner: String, partnerDetails,
						  collisionLocation: Vector2, postVelocity: Vector2) -> void:
	if collisionEvent["t"] < t:
		return 
	collisionEvent["t"] = t
	collisionEvent["partner"] = partner
	collisionEvent["partner details"] = partnerDetails
	collisionEvent["collision location"] = collisionLocation
	collisionEvent["post velocity"] = postVelocity


func updateCollisionEventFromGeometricData(collisionEvent: Dictionary,
										   partner: String,
										   geometricCollisionData:Dictionary) -> void:
	if collisionEvent["t"] < geometricCollisionData["t"]:
		return
	for key in geometricCollisionData:
		collisionEvent[key] = geometricCollisionData[key]
	collisionEvent["partner"] = partner


func updateGeometricCollision(geometricCollisionData:Dictionary, t: float,
							  partnerDetails: String,
							  collisionLocation: Vector2,
							  postVelocity: Vector2) -> void:
	if t < 0 or t > geometricCollisionData["t"]: return
	geometricCollisionData["t"] = t
	geometricCollisionData["partner details"] = partnerDetails
	geometricCollisionData["collision location"] = collisionLocation
	geometricCollisionData["post velocity"] = postVelocity
