extends CharacterBody2D

@export var speed := 300.0
@export var shot_scene: PackedScene
@onready var pp: Marker2D = $PP

var shot_color = Color8(255, 255, 0, 128)
@onready var camera: Camera2D = $Camera2D

@export var pee_speed := 180.0
@export var pee_lifetime := 0.4 # seconds

var pee_speed_modifier := .25
var pee_lifetime_modifier := .5

var player_facing_dir = Vector2.UP
signal player_died

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var shot_sfx: AudioStreamPlayer2D = $ShotSFX
@onready var pee_up_sfx: AudioStreamPlayer2D = $PeeUpSfx

func _ready():
	add_to_group("player")

#func _input(event):
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			#if camera.zoom.x <= 6.5:
				#camera.zoom.x += 0.5
				#camera.zoom.y += 0.5
			#
		#if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			#if camera.zoom.x >= 2.5:
				#camera.zoom.x -= 0.5
				#camera.zoom.y -= 0.5

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

	var look_dir
	if Input.get_connected_joypads().size() > 0:
		var aim_vector = Vector2.ZERO
		aim_vector.x = Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left")
		aim_vector.y = Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")

		if aim_vector.length() > 0: # Ensure the stick is not at the deadzone
			look_dir = aim_vector # Rotate your object to face the direction of the aim vector
			player_facing_dir = look_dir
			rotation = look_dir.angle() + PI/2
	else:
		# Rotate to face mouse
		var mouse_pos = get_global_mouse_position()
		look_dir = (mouse_pos - global_position).normalized()
		player_facing_dir = look_dir
		rotation = look_dir.angle() + PI/2

func shoot():
	var shot = shot_scene.instantiate()
	shot_sfx.play()
	shot.global_position = pp.global_position
	
	# apply color
	match shot_color:
		"orange":
			shot.set_color(Color8(255, 125, 0, 200))
		"yellow":
			shot.set_color(Color8(255, 255, 0, 200))
		"green":
			shot.set_color(Color8(0.0, 125, 98, 200))
		"purple":
			shot.set_color(Color8(132, 30, 203, 200))
	
	# Apply player's current values
	shot.pee_speed = pee_speed
	shot.pee_lifetime *= pee_lifetime
	
	##shot.position = global_position + player_facing_dir * 20
	shot.set_direction(player_facing_dir)
	get_parent().add_child(shot)
	# Connect enemy hit signal from shot to main
	shot.connect("enemy_hit", Callable(self.get_parent(), "_on_shot_enemy_hit"))

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		print("Player collided with enemy!")
		emit_signal("player_died")
		queue_free()  # Remove player
 
func apply_powerup(effect: String, color: String):		
	pee_up_sfx.play(0.0)
	if effect == "rate_up":
		pee_speed += pee_speed_modifier
	if effect == "distance_up":
		pee_lifetime += pee_lifetime_modifier
	shot_color = color

func on_hit():
	print("Enemy hit and removed:", name)
	queue_free()
