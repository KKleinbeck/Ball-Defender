extends Node


enum EntityType {Empty, Standard, Damage, TimeUp, Currency, PremiumCurrency, Charge}
enum State {RUNNING, HALTING, GAMEOVER}
var state: State = State.RUNNING


func _ready() -> void:
	set_process(false)


func updateCollisionEvent(collisionEvent: Dictionary, t: float, partner: String, partner_details, collision_location: Vector2) -> void:
	# TODO: Simultaneous collision events
	if collisionEvent["t"] < t:
		return 
	collisionEvent["t"] = t
	collisionEvent["partner"] = partner
	collisionEvent["partner details"] = partner_details
	collisionEvent["collision location"] = collision_location
