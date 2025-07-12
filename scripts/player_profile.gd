extends Node

class_name PlayerProfile

var username: String = "zerocool"
var all_time_nazi_kills: int = 0
var one_game_nazi_kills: int = 0
var powerups_used: int = 0

func to_dict() -> Dictionary:
	return {
		"username": username,
		"all_time_nazi_kills": all_time_nazi_kills,
		"one_game_nazi_kills": one_game_nazi_kills,
		"powerups_used": powerups_used
	}

func from_dict(data: Dictionary):
	username = data.get("username", username)
	one_game_nazi_kills = data.get("one_round_nazis_killed", one_game_nazi_kills)
	all_time_nazi_kills = data.get("all_time_nazi_kills", all_time_nazi_kills)
	powerups_used = data.get("powerups_used", powerups_used)
