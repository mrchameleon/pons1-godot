extends CharacterBody2D

@export var speed := 300.0
@export var shot_scene: PackedScene
@onready var pp: Marker2D = $PP

var shot_color = Color8(255, 255, 0, 128)
@onready var camera: Camera2D = $Camera2D

# firing/pee container
var pee_level = Globals.pee_container_max
var pee_cooldown = 0.1
var pee_timer = 0.0

var pee_speed = Globals.base_pee_speed
var pee_lifetime = Globals.base_pee_life
var pee_speed_modifier = Globals.powerup_pee_speed_modifier
var pee_lifetime_modifier = Globals.powerup_pee_lifetime_modifier

var player_facing_dir = Vector2.UP

signal player_died
signal pee_changed(current: float, max: float)

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var shot_sfx: AudioStreamPlayer2D = $ShotSFX
@onready var pee_up_sfx: AudioStreamPlayer2D = $PeeUpSfx

func _ready():
	add_to_group("player")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			if camera.zoom.x <= 1.8: 
				camera.zoom.x += 0.2
				camera.zoom.y += 0.2
				#print(camera.zoom.x, camera.zoom.y)
			
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			if camera.zoom.x >= 0.6:
				camera.zoom.x -= 0.2
				camera.zoom.y -= 0.2
				#print(camera.zoom.x, camera.zoom.y)

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

	# peeing
	pee_timer -= delta
	print("Input shoot : %s" % Input.is_action_pressed("shoot"))
	print("pee suppress: %s" % Globals.joystick_pee_suppress)
	if Input.is_action_pressed("shoot") and Globals.joystick_pee_suppress == false:
		if pee_level >= Globals.pee_cost_per_shot and pee_timer <= 0:
			shoot()
			pee_level -= Globals.pee_cost_per_shot
			pee_timer = pee_cooldown
			emit_signal("pee_changed", pee_level, Globals.pee_container_max)
		else:
			pee_timer = 0.0
			
	# pee regeneration
	if Input.is_action_pressed("shoot"):
		pee_level += Globals.pee_regen_during_shoot * delta
	else:
		pee_level += Globals.pee_regen_rate * delta

	pee_level = clamp(pee_level, 0.0, Globals.pee_container_max)
	emit_signal("pee_changed", pee_level, Globals.pee_container_max)

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
	if shot_sfx.playing == false:
		shot_sfx.play()
	shot.global_position = pp.global_position
	shot.set_direction(player_facing_dir)
	
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
	Globals.powerups_used += 1
	pee_up_sfx.play(0.0)
	

	
	if color == "blue":
		pee_level = Globals.pee_container_max
	else:
		pee_level += 1000
	emit_signal("pee_changed", pee_level, Globals.pee_container_max)
	
	if effect == "rate_up":
		pee_speed += pee_speed_modifier
	if effect == "distance_up":
		pee_lifetime += pee_lifetime_modifier
	if effect == "player_speed_up":
		speed += 2
	shot_color = color

func on_hit():
	print("Enemy hit and removed:", name)
	queue_free()
