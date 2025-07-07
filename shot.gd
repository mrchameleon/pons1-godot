extends Area2D

# internal values/defaults - Player will override
@export var pee_speed := 180.0
@export var pee_lifetime := 0.4 # seconds

var color = Color8(255, 255, 0, 128)

var player = Globals.player
var direction: Vector2 = Vector2.ZERO
var time_alive := 0.0
@onready var kill_sfx: AudioStreamPlayer2D = $KillSFX

signal enemy_hit(enemy: Node)
@onready var sprite: Sprite2D = $Sprite2D 

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	sprite.modulate = color

func set_color(c: Color):
	color = c
	if sprite: 
		print("Color applied to shot:", c)
		sprite.modulate = c

func _physics_process(delta):
	time_alive += delta
	if time_alive > pee_lifetime:
		queue_free()
	
	global_position += direction * pee_speed * delta

	# Remove shot if off screen
	if player and global_position.distance_to(player.global_position) > 3000:
		queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _on_body_entered( body: Node):
	if body.is_in_group("enemies"):
		kill_sfx.play()
		emit_signal("enemy_hit", body)
		queue_free()
