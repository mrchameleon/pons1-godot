extends Node2D

@onready var bg: TextureRect = $"../ParallaxBackground/ParallaxLayer/Stars"
@export var wave_shaders: Array[ShaderMaterial] = []
@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var splat: PackedScene
@export var blood_scene: PackedScene

@onready var pee_bar: TextureProgressBar = $"../UI/Control/Panel/TextureProgressBar"
@onready var play_again: Button = $"../UI/Control/PlayAgain"
@onready var main_text: Label = $"../UI/Control/MainText"
@onready var in_game_kills: Label = $"../UI/Control/InGameKills"
@onready var wavedebug: Label = $"../UI/Control/wavedebug"
@onready var lifedebug: Label = $"../Debug/lifedebug"
@onready var ratedebug: Label = $"../Debug/ratedebug"
@onready var playerspeed: Label = $"../Debug/playerspeed"

@onready var leader_name_entry: TextEdit = $"../UI/Control/LeaderNameEntry"
@onready var leader_submit: Button = $"../UI/Control/LeaderSubmit"

@onready var debug_panel: CanvasLayer = $"../Debug"

@onready var holyshit: AudioStreamPlayer2D = $"../holyshit"
@onready var death_sfx: AudioStreamPlayer2D = $"../DeathSFX"
@onready var enemy_die: AudioStreamPlayer2D = $"../EnemyDie"

@onready var base_pee_speed_input: LineEdit = $"../Debug/VBoxContainer/base_pee_speed/base_pee_speed_input"
@onready var base_pee_life_input: LineEdit = $"../Debug/VBoxContainer/base_pee_life/base_pee_life_input"
@onready var powerup_interval_input: LineEdit = $"../Debug/VBoxContainer/powerup_interval/powerup_interval_input"
@onready var powerup_speed_mod_input: LineEdit = $"../Debug/VBoxContainer/powerup_speed_mod/powerup_speed_mod_input"
@onready var powerup_dist_input: LineEdit = $"../Debug/VBoxContainer/powerup_dist/powerup_dist_input"
@onready var wave_interval_input: LineEdit = $"../Debug/VBoxContainer/wave_interval/wave_interval_input"
@onready var base_enemy_count_input: LineEdit = $"../Debug/VBoxContainer/base_enemy_count/base_enemy_count_input"
@onready var base_enemy_speed_input: LineEdit = $"../Debug/VBoxContainer/base_enemy_speed/base_enemy_speed_input"


@onready var debug: CanvasLayer = $"../Debug"

@export var powerup_scene: PackedScene
var crosshair = load("res://images/crosshair.png")
var debug_used_cheat_mode = false
var leader_post_url = "https://podagi.com/api/post_leader"
@onready var post_leader_http: HTTPRequest = $"../post_leader_http"

signal settings_applied()

var powerup_timer := 0.0
var game_started = false
var player_ref: Node = null
var score: int = 0
var is_game_over: bool = false

var enemies_container: Node2D = null
var wave_timer := 0.0

var wave_count := 1

var powerup_spawn_interval = Globals.powerup_spawn_interval
var wave_interval = Globals.wave_interval
var base_enemy_count = Globals.base_enemy_count
var base_enemy_speed = Globals.base_enemy_speed
var speed_increase_per_wave = Globals.speed_increase_per_wave

@onready var music: AudioStreamPlayer2D = $"../Music"

const PROFILE_PATH = "user://profile.json"
var player_profile = PlayerProfile.new()

# mobile joystick
@onready var joystick: VirtualJoystick = $"../UI/L_Joy"
@onready var aim_joystick: VirtualJoystick = $"../UI/R_Joy"

@onready var joystick_rect: Rect2 = joystick.get_global_rect()
var active_touches := {}  # index -> { pos = Vector2, in_joystick = bool }
# All touchscreen touches, tagged with value in/out of joystick area

func is_shoot_suppressed() -> bool:
	#if OS.get_name() != "Android":
		#return false  # Only suppress on mobile

	if active_touches.is_empty():
		return true  # No touches

	for touch in active_touches.values():
		if not touch["in_joystick"]:
			return false  # At least one touch not in joystick
	return true  # All touches are joystick-only


func _process(delta):
	# NOTE: Turn on "enable_touch_from_mouse" for android debugging in windows
	# ALSO turn it back OFF, before exporting the Windows Build!
	
	print(active_touches)
	Globals.joystick_pee_suppress = is_shoot_suppressed()

	if leader_name_entry.text != "":
		leader_submit.disabled = false
	
	if music.playing == false:
		music.playing = true

	if not player_ref:
		return

	powerup_timer += delta
	if powerup_timer >= Globals.powerup_spawn_interval:
		powerup_timer = 0.0
		spawn_powerup()

	wave_timer += delta
	if wave_timer >= Globals.wave_interval:
		wave_timer = 0
		wave_count += 1
		if wave_count == 20:
			holyshit.play(0.0)
		spawn_wave()

	ratedebug.text = "pee_rate: %0.2f" % player_ref.pee_speed
	lifedebug.text = "pee_range: %0.2f" % player_ref.pee_lifetime
	playerspeed.text = "player_speed: %s" % int(player_ref.speed)
	wavedebug.text = "wave: %s" % int(wave_count)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			var is_in_joystick = joystick.get_global_rect().has_point(event.position)
			active_touches[event.index] = {
				"pos": event.position,
				"in_joystick": is_in_joystick
			}
		else:
			active_touches.erase(event.index)

	elif event is InputEventScreenDrag:
		if active_touches.has(event.index):
			active_touches[event.index]["pos"] = event.position

	if event.is_action_pressed("any_button") and game_started == false:
		start_game()
	if event.is_action_pressed("debug"):
		if debug_panel.visible == true:
			game_started = false
		debug_panel.visible = !debug_panel.visible

func _ready():
	Input.set_use_accumulated_input(false)
	settings_applied.connect(_apply_settings)

	base_pee_speed_input.text = str(Globals.base_pee_speed)
	base_pee_life_input.text = str(Globals.base_pee_life)
	powerup_speed_mod_input.text = str(Globals.powerup_pee_speed_modifier)
	powerup_dist_input.text = str(Globals.powerup_pee_lifetime_modifier)
	powerup_interval_input.text = str(Globals.powerup_spawn_interval)
	wave_interval_input.text = str(Globals.wave_interval)
	base_enemy_count_input.text = str(Globals.base_enemy_count)
	base_enemy_speed_input.text = str(Globals.base_enemy_speed)
	
	
	enemies_container = Node2D.new()
	add_child(enemies_container)
	music.playing = true
	play_again.visible = false
	play_again.pressed.connect(_on_retry_pressed)
	start_game()

func _on_pee_changed(current, max):
	pee_bar.value = current

func _apply_settings(powerup, wave, count, speed, increase):
	powerup_spawn_interval = powerup
	wave_interval = wave
	base_enemy_count = count
	base_enemy_speed = speed
	speed_increase_per_wave = increase

	start_game()

func _on_retry_pressed():
	main_text.visible = false
	start_game()

func _on_player_died():
	game_started = false
	holyshit.play(0.0)
	death_sfx.play()
	
	if debug_used_cheat_mode == false:
		leader_name_entry.visible = true
		leader_submit.visible = true
	
	main_text.text = "Nazis got you. But you killed %d of them" % score
	main_text.visible = true
	play_again.visible = true
	if player_ref:	
		player_ref.queue_free()
	player_ref = null

	# Clear all existing enemies
	for child in get_children():
		if child.is_in_group("enemies"):
			child.queue_free()
		if child.is_in_group("items"):
			child.queue_free()

	#  Reset difficulty scaling for next game
	wave_timer = 0.0
	wave_count = 1

func spawn_powerup():
	var powerup = powerup_scene.instantiate()
	var player_pos = Globals.player.global_position
	 
	var min_distance := 250
	var max_distance := 750
	
	var angle = randf() * TAU
	var distance = randf_range(min_distance, max_distance)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	
	powerup.global_position = player_pos + offset
	add_child(powerup)

func update_score():
	in_game_kills.text = "Kills: %d" % score

func start_game():
	leader_name_entry.visible = false
	leader_submit.visible = false
	
	Input.set_custom_mouse_cursor(crosshair)
	game_started = true
	score = 0
	update_score()
	# Hide UI 
	play_again.visible = false
	main_text.visible = false

	# Clear old game objects
	if player_ref:
		player_ref.queue_free()
	player_ref = player_scene.instantiate()
	Globals.player = player_ref
	Globals.powerups_used = 0
	player_ref.pee_level = 3000 # half-ish bladder start
	player_ref.pee_changed.connect(Callable(self, "_on_pee_changed"))
	player_ref.player_died.connect(Callable(self, "_on_player_died"))
	add_child(player_ref)
	player_ref.position = get_viewport_rect().size / 2

	for child in enemies_container.get_children():
		child.queue_free()

	# Linear growth formula
	var enemy_count = floor(Globals.base_enemy_count * pow(1.1, wave_count))
	# regular spawn loop:
	for i in range(enemy_count):
		spawn_enemy()

func _on_shot_enemy_hit(enemy: Node):
	if enemy.dead == false and enemy.is_inside_tree():
		enemy.dead = true
		var blood = blood_scene.instantiate()
		blood.global_position = enemy.global_position
		get_tree().current_scene.add_child(blood)
			
		var poo = splat.instantiate()
		add_child(poo)
		poo.global_position = enemy.global_position
		
		enemy_die.play()
		score += 1
		in_game_kills.text = "Kills: %d" % score
		enemy.queue_free()


func spawn_wave():
	update_background_shader()
	var enemy_count = Globals.base_enemy_count + wave_count
	var speed = clamp(base_enemy_speed * pow(1.05, wave_count), base_enemy_speed, 500)

	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		enemy.set_player(player_ref)
		enemy.speed = speed
		add_child(enemy)
		enemy.position = get_random_spawn_position(player_ref.global_position)
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

func update_background_shader():
	var material = bg.material
	var color_pairs = [
		[Color(0.2, 0.6, 1.0), Color(1.0, 0.9, 0.4)],   # Electric blue + soft yellow
		[Color(0.1, 0.1, 0.1), Color(1.0, 0.1, 0.2)],   # Deep black + red (space danger)
		[Color(0.5, 0.9, 1.0), Color(1.0, 0.4, 0.6)],   # Cyan sky + pink clouds
		[Color(0.3, 0.0, 0.5), Color(1.0, 0.6, 0.0)],   # Purple + orange
		[Color(0.2, 0.2, 0.2), Color(0.8, 0.9, 1.0)],   # Foggy dark + icy white-blue
		[Color(0.6, 0.8, 0.3), Color(0.2, 0.3, 0.9)],   # Lime green + ultramarine
		[Color(0.9, 0.7, 0.1), Color(0.0, 0.0, 0.2)],   # Golden glow + deep night
		[Color(0.8, 0.3, 0.4), Color(0.0, 0.8, 0.6)],   # Coral red + teal
		[Color(1.0, 1.0, 1.0), Color(0.3, 0.3, 0.3)]    # Classic white + shadow grey
	]
	
	if material is ShaderMaterial:
		#var pair = color_pairs[randi() % color_pairs.size()]
		#material.set_shader_parameter("colour_multiplier", pair[0])
		#material.set_shader_parameter("colour_multiplier2", pair[1])
		# for totally random colors:
		var rand_color1 = Color(randf(), randf(), randf(), 1.0)
		var rand_color2 = Color(randf(), randf(), randf(), 1.0)
		material.set_shader_parameter("colour_multiplier", rand_color1)
		material.set_shader_parameter("colour_multiplier2", rand_color2)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.set_player(player_ref)
	enemies_container.add_child(enemy)
	enemy.position = get_random_spawn_position(player_ref.global_position)


func get_random_spawn_position(player_pos: Vector2) -> Vector2:
	var min_distance := 800   # Minimum distance from player
	var max_distance := 1600  # Maximum distance from player

	# Random angle in radians
	var angle := randf() * TAU
	var distance := randf_range(min_distance, max_distance)
	
	var offset := Vector2(cos(angle), sin(angle)) * distance
	return player_pos + offset


func _on_defaults_pressed() -> void:
	player_ref.pee_speed = Globals.base_pee_speed
	player_ref.pee_lifetime = Globals.base_pee_life
	player_ref.pee_speed_modifier = Globals.powerup_pee_speed_modifier
	player_ref.pee_lifetime_modifier = Globals.powerup_pee_lifetime_modifier

	powerup_spawn_interval = Globals.def_powerup_spawn_interval
	wave_interval = Globals.def_wave_interval
	base_enemy_count = Globals.def_base_enemy_count
	base_enemy_speed = Globals.def_base_enemy_speed
	speed_increase_per_wave = Globals.def_speed_increase_per_wave
	debug_panel.visible = false
	debug_used_cheat_mode = false

func _on_leader_submit_pressed() -> void:
	var username = leader_name_entry.text.to_lower()
	leader_submit.disabled = true
	if not FileAccess.file_exists(PROFILE_PATH):
		print("No profile found. Creating default profile.")
		PlayerManager.save_profile()
	else:
		print("Profile exists. Loading...")
		PlayerManager.load_profile()
	
	PlayerManager.profile.username = username
	PlayerManager.profile.all_time_nazi_kills = PlayerManager.profile.all_time_nazi_kills + score
	PlayerManager.profile.one_game_nazi_kills = score
	PlayerManager.profile.powerups_used += Globals.powerups_used
	PlayerManager.save_profile()
	var leader_post_json = JSON.stringify(PlayerManager.profile.to_dict())
	var headers = ["Content-Type: application/json"]
	print("POSTing to leaderboard...?")
	post_leader_http.use_threads = false
	post_leader_http.timeout = 5.0
	post_leader_http.request(leader_post_url, headers, HTTPClient.METHOD_POST, leader_post_json)
	leader_submit.text = "communicating..."

func _on_post_leader_http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		OS.alert("Failed to submit score. Error code: %d" % result)
		leader_submit.disabled = false
		return
	OS.alert("high score submitted!")
	leader_submit.text = "Submit"
	print(result)
	print(response_code)
	get_tree().change_scene_to_file("res://title.tscn")
	# user-agent: GodotEngine/4.4.stable.official (Windows)

func _on_apply_pressed() -> void:
	Globals.base_pee_speed = base_pee_speed_input.text.to_float()
	Globals.base_pee_life = base_pee_life_input.text.to_float()
	Globals.powerup_pee_speed_modifier = powerup_speed_mod_input.text.to_float()
	Globals.powerup_pee_lifetime_modifier = powerup_dist_input.text.to_float()
	Globals.powerup_spawn_interval = powerup_interval_input.text.to_float()
	Globals.wave_interval = wave_interval_input.text.to_float()
	Globals.base_enemy_count = base_enemy_count_input.text.to_int()
	Globals.base_enemy_speed = base_enemy_speed_input.text.to_float()
	emit_signal("settings_applied")
	debug_used_cheat_mode = true
	debug.visible = false
