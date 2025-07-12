extends Control

signal play
@onready var button: Button = $Panel/Button

@onready var pee: CPUParticles2D = $pee

var phrase_pool = []
@onready var phrase_of_the_day: RichTextLabel = $PhraseOfTheDay
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var leader_get_url = "https://podagi.com/api/leader"
@onready var leader_get: HTTPRequest = $HTTPRequest
@onready var pissers: RichTextLabel = $pissers

@onready var plasma: ColorRect = $ColorRect

var SPECTRUM = [
	"#FF0000",  # Red
	"#FF4000",  # Red-Orange
	"#FF8000",  # Orange
	"#FFBF00",  # Amber
	"#FFFF00",  # Yellow
	"#BFFF00",  # Yellow-Green
	"#80FF00",  # Lime
	"#40FF00",  # Lime-Green
	"#00FF00",  # Green
	"#00FF80",  # Green-Cyan
	"#00FFFF",  # Cyan
	"#00BFFF",  # Deep Sky Blue
	"#0080FF",  # Dodger Blue
	"#0040FF",  # Royal Blue
	"#0000FF",  # Blue
	"#4000FF",  # Indigo
	"#8000FF",  # Violet
	"#BF00FF",  # Purple
	"#FF00FF",  # Magenta
	"#FF40BF"   # Hot Pink
]

func _ready():
	var headers = ["Content-Type: application/json"]
	print("leader api call")
	leader_get.request(leader_get_url, headers, HTTPClient.METHOD_GET)
	phrase_of_the_day.text = random_phrase()

func phrase_setup():
	var phrases = FileAccess.open('res://phrases.txt', FileAccess.READ)
	if phrase_pool == []:
		# setup random chat comments pool
		while not phrases.eof_reached(): 
			phrase_pool.append(phrases.get_line())
		phrases.close()
	phrases.close()

func random_phrase():
	if phrase_pool == []:
		phrase_setup()
	return phrase_pool.pick_random()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _input(event):
	if event.is_action_pressed("any_button"):
		get_tree().change_scene_to_file("res://main.tscn")

func _process(_delta):
	var offset := Vector2(22, 10)  # tweak this to match
	pee.position = get_global_mouse_position() + offset

func _on_phrase_button_pressed() -> void:
	audio_stream_player_2d.play(0.0)
	var choice = random_phrase()
	if choice != '': 
		#godot keeps adding a blank newline at the end
		phrase_of_the_day.text = random_phrase()


func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	print("leader api req complete:")
	print(result)
	print(response_code)
	var body_string = body.get_string_from_utf8()
	#print(body_string)
	var data = JSON.parse_string(body_string)
	var score_text = ""
	var c_index = 0
	for user in data["stats"]:
		var col = SPECTRUM[c_index]
		score_text += "[color=%s]%s[/color] killed %s nazis\n" % [col, user['username'], int(user['one_game_nazi_kills'])]
		c_index += 1

	pissers.text = score_text
