extends Node2D

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene

@onready var play_button: Button = $"../Control/PlayButton"
@onready var play_again: Button = $"../Control/PlayAgain"

@onready var in_game_kills: Label = $"../Control/InGameKills"
@onready var game_over_text: Label = $"../Control/GameOverText"
@onready var death_sfx: AudioStreamPlayer2D = $"../DeathSFX"
@onready var enemy_die: AudioStreamPlayer2D = $"../EnemyDie"



var player_ref: Node = null
var score: int = 0
var is_game_over: bool = false

var enemies_container: Node2D = null
var wave_timer := 0.0
var wave_interval := 3.0
var wave_count := 1

var base_enemy_count := 2
var base_enemy_speed := 100.0
var speed_increase_per_wave := 15.0


@onready var music: AudioStreamPlayer2D = $"../Music"

func _ready():
	music.playing = true

	play_button.visible = true
	play_again.visible = false
	game_over_text.visible = false
	
	play_button.pressed.connect(_on_play_pressed)
	play_again.pressed.connect(_on_retry_pressed)
	
	enemies_container = Node2D.new()
	add_child(enemies_container)

func _on_play_pressed():
	start_game()

func _on_retry_pressed():
	game_over_text.visible = false
	start_game()

func _on_player_died():
	death_sfx.play()
	game_over_text.text = "Nazis got you. But you killed %d of them" % score
	game_over_text.visible = true
	play_again.visible = true
	if player_ref:
		player_ref.queue_free()
	player_ref = null

	# Clear all existing enemies
	for child in get_children():
		if child.is_in_group("enemies"):
			child.queue_free()
	#  Reset difficulty scaling for next game
	wave_timer = 0.0
	wave_count = 1

func update_score():
	in_game_kills.text = "Kills: %d" % score

func start_game():
	score = 0
	update_score()
	# Hide UI
	play_button.visible = false
	play_again.visible = false
	
	# Clear old game objects
	if player_ref:
		player_ref.queue_free()
	player_ref = player_scene.instantiate()
	player_ref.player_died.connect(Callable(self, "_on_player_died"))
	add_child(player_ref)
	player_ref.position = get_viewport_rect().size / 2

	for child in enemies_container.get_children():
		child.queue_free()

	# Spawn enemies
	for i in range(5):
		spawn_enemy()


func _on_shot_enemy_hit(enemy: Node):
	if enemy and enemy.is_inside_tree():
		enemy_die.play()
		score += 1
		in_game_kills.text = "Kills: %d" % score
		enemy.queue_free()

func _process(delta):
	if not player_ref:
		return

	wave_timer += delta
	if wave_timer >= wave_interval:
		wave_timer = 0
		wave_count += 1
		spawn_wave()

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
