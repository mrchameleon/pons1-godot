extends Node2D

@onready var bg: TextureRect = $"../ParallaxBackground/ParallaxLayer/ColoredTilesBg"
@export var wave_shaders: Array[ShaderMaterial] = []

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var splat: PackedScene
@export var blood_scene: PackedScene

@onready var play_again: Button = $"../CanvasLayer/Control/PlayAgain"
@onready var main_text: Label = $"../CanvasLayer/Control/MainText"
@onready var in_game_kills: Label = $"../CanvasLayer/Control/InGameKills"
@onready var wavedebug: Label = $"../CanvasLayer/Control/wavedebug"
@onready var lifedebug: Label = $"../CanvasLayer/Control/lifedebug"
@onready var ratedebug: Label = $"../CanvasLayer/Control/ratedebug"

@onready var debug_panel: CanvasLayer = $"../Debug"


@onready var powerup_interval_input: LineEdit = $VBoxContainer/powerup_interval/powerup_interval_input
@onready var wave_interval_input: LineEdit = $VBoxContainer/wave_interval/wave_interval_input
@onready var base_enemy_count_input: LineEdit = $VBoxContainer/base_enemy_count/base_enemy_count_input
@onready var base_enemy_speed_input: LineEdit = $VBoxContainer/base_enemy_speed/base_enemy_speed_input
@onready var speed_increase_per_wave_input: LineEdit = $VBoxContainer/speed_increase_per_wave/speed_increase_per_wave_input



@onready var death_sfx: AudioStreamPlayer2D = $"../DeathSFX"
@onready var enemy_die: AudioStreamPlayer2D = $"../EnemyDie"

@export var powerup_scene: PackedScene



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

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("any_button") and game_started == false:
		start_game()
	if event.is_action_pressed("debug"):
		if debug_panel.visible == true:
			game_started = false
		debug_panel.visible = !debug_panel.visible

func _ready():
	debug_panel.settings_applied.connect(_apply_settings)
	enemies_container = Node2D.new()
	add_child(enemies_container)
	music.playing = true
	play_again.visible = false
	play_again.pressed.connect(_on_retry_pressed)
	start_game()

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
	death_sfx.play()
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
	
	var min_distance := 400
	var max_distance := 900
	
	var angle = randf() * TAU
	var distance = randf_range(min_distance, max_distance)
	var offset = Vector2(cos(angle), sin(angle)) * distance
	
	powerup.global_position = player_pos + offset
	add_child(powerup)

func update_score():
	in_game_kills.text = "Kills: %d" % score

func start_game():
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
	player_ref.player_died.connect(Callable(self, "_on_player_died"))
	add_child(player_ref)
	player_ref.position = get_viewport_rect().size / 2

	for child in enemies_container.get_children():
		child.queue_free()

	# Spawn extra enemies sometimes
	var extra_enemies = 0
	if wave_count % 2 == 0:
		extra_enemies = [1,2,3].pick_random()
	
	# regular spawn loop:
	for i in range(Globals.base_enemy_count + extra_enemies):
		spawn_enemy()

func _on_shot_enemy_hit(enemy: Node):
	if enemy and enemy.is_inside_tree():
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

func _process(delta):
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
		spawn_wave()

	ratedebug.text = "pee_rate: %0.2f" % player_ref.pee_speed
	lifedebug.text = "pee_range: %0.2f" % player_ref.pee_lifetime
	wavedebug.text = "wave: %s" % int(wave_count)

func spawn_wave():
	update_background_shader()
	var enemy_count = Globals.base_enemy_count + wave_count
	var enemy_speed = Globals.base_enemy_speed + wave_count * Globals.speed_increase_per_wave

	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		enemy.set_player(player_ref)
		enemy.speed = enemy_speed
		add_child(enemy)
		enemy.position = get_random_spawn_position(player_ref.global_position)
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

func update_background_shader():
	if wave_count < wave_shaders.size():
		bg.material = wave_shaders.pick_random()
	else:
		bg.material = wave_shaders[0]

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
	powerup_spawn_interval = Globals.def_powerup_spawn_interval
	wave_interval = Globals.def_wave_interval
	base_enemy_count = Globals.def_base_enemy_count
	base_enemy_speed = Globals.def_base_enemy_speed
	speed_increase_per_wave = Globals.def_speed_increase_per_wave
