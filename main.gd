extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var splat: PackedScene
@export var blood_scene: PackedScene

@onready var play_again: Button = $"../Control/PlayAgain"

@onready var in_game_kills: Label = $"../Control/InGameKills"

@onready var main_text: Label = $"../Control/MainText"
@onready var death_sfx: AudioStreamPlayer2D = $"../DeathSFX"
@onready var enemy_die: AudioStreamPlayer2D = $"../EnemyDie"

@export var powerup_scene: PackedScene


@onready var wavedebug: Label = $"../Control/wavedebug"
@onready var ratedebug: Label = $"../Control/ratedebug"
@onready var lifedebug: Label = $"../Control/lifedebug"


var powerup_timer := 0.0
var game_started = false
var player_ref: Node = null
var score: int = 0
var is_game_over: bool = false

var enemies_container: Node2D = null
var wave_timer := 0.0
var wave_interval := 4.0  # was 3
var wave_count := 1

@export var powerup_spawn_interval := 5.0  # seconds

var base_enemy_count := 4
var base_enemy_speed := 69   # was 100.0

var speed_increase_per_wave := 15.0  # was 15


@onready var music: AudioStreamPlayer2D = $"../Music"

func _input(event):
	if event.is_action_pressed("exit"):
		get_tree().quit()
	if event.is_action_pressed("any_button") and game_started == false:
		start_game()

func _ready():
	enemies_container = Node2D.new()
	add_child(enemies_container)
	music.playing = true
	play_again.visible = false
	play_again.pressed.connect(_on_retry_pressed)
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
	var screen_size = get_viewport_rect().size
	powerup.position = Vector2(randf() * screen_size.x, randf() * screen_size.y)
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

	# Spawn enemies
	for i in range(base_enemy_count):
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
	if powerup_timer >= powerup_spawn_interval:
		powerup_timer = 0.0
		spawn_powerup()

	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0
		wave_count += 1
		spawn_wave()

	ratedebug.text = "pee_rate: %0.2f" % player_ref.pee_speed
	lifedebug.text = "pee_range: %0.2f" % player_ref.pee_lifetime
	wavedebug.text = "wave: %s" % int(wave_count)

func spawn_wave():
	var enemy_count = base_enemy_count + wave_count
	var enemy_speed = base_enemy_speed + wave_count * speed_increase_per_wave

	for i in range(enemy_count):
		var enemy = enemy_scene.instantiate()
		enemy.set_player(player_ref)
		enemy.speed = enemy_speed
		add_child(enemy)
		enemy.position = get_random_spawn_position()
		enemy.connect("enemy_died", Callable(self, "_on_enemy_died"))

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	enemy.set_player(player_ref)
	enemies_container.add_child(enemy)
	enemy.position = get_random_spawn_position()

func get_random_spawn_position() -> Vector2:
	var screen_size = get_viewport_rect().size
	match randi() % 4:
		0:
			return Vector2(randf() * screen_size.x, 0) # top
		1:
			return Vector2(randf() * screen_size.x, screen_size.y) # bottom
		2:
			return Vector2(0, randf() * screen_size.y) # left
		3:
			return Vector2(screen_size.x, randf() * screen_size.y) # right
		_:
			return screen_size / 2
