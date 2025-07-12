extends Node

const SAVE_PATH := "user://profile.json"

var profile := PlayerProfile.new()

func _ready():
	load_profile()

func save_profile():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var json = JSON.stringify(profile.to_dict(), "\t")
	file.store_string(json)
	file.close()
	print("Profile saved.")

func load_profile():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if typeof(json) == TYPE_DICTIONARY:
			profile.from_dict(json)
			print("Profile loaded.")
	else:
		print("No profile found. Using default.")
