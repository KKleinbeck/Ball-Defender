extends Node


func upgradeEffect(upgrade: String, level: int) -> String:
	var value = Player.levelingDetails[upgrade]["start"] + \
		level * Player.levelingDetails[upgrade]["levelBonus"]
	if upgrade == "damage":
		var guarantee = int(value)
		var chance = int(100 * (value - guarantee + 0.001))
		if 0 == chance:
			return tr("UPGRADE_DAMAGE_EFFECT").format({"value": guarantee})
		return tr("UPGRADE_DAMAGE_EFFECT_LONG").format({"value": guarantee, "chance": chance})
	elif "prob" in upgrade:
		value *= 100
	return tr("UPGRADE_" + upgrade.to_upper() + "_EFFECT").format({"value": value})
