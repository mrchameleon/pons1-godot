extends CharacterBody2D

@export var speed := 300.0
@export var shot_scene: PackedScene

var player_facing_dir = Vector2.UP
signal player_died

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var shot_sfx: AudioStreamPlayer2D = $ShotSFX

func _ready():
	pass

func _physics_process(delta):
	var input_dir = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

	velocity = input_dir * speed
	var collision = move_and_collide(velocity * delta)
	
	if collision:
		var collider = collision.get_collider()
		if collider and collider.is_in_group("enemies"):
			print("Player collided with enemy:", collider.name)
			emit_signal("player_died")
			queue_free()

	if Input.is_action_pressed("shoot"):
		shoot()

	# Rotate to face mouse
	var mouse_pos = get_global_mouse_position()
	var look_dir = (mouse_pos - global_position).normalized()
	player_facing_dir = look_dir
	rotation = look_dir.angle() + PI/2

func shoot():
	var shot = shot_scene.instantiate()
	shot_sfx.play()
	shot.position = global_position + player_facing_dir * 20
	shot.set_direction(player_facing_dir)
	get_parent().add_child(shot)
	# Connect enemy hit signal from shot to main
	shot.connect("enemy_hit", Callable(self.get_parent(), "_on_shot_enemy_hit"))

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		print("Player collided with enemy!")
		emit_signal("player_died")
		queue_free()  # Remove player

func on_hit():
	print("Enemy hit and removed:", name)
	queue_free()
