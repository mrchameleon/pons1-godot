extends Area2D

@export var speed := 600.0
var direction: Vector2 = Vector2.ZERO
@onready var kill_sfx: AudioStreamPlayer2D = $KillSFX

signal enemy_hit(enemy: Node)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta):
	position += direction * speed * delta

	# Remove shot if off screen
	if not get_viewport_rect().has_point(position):
		queue_free()

func set_direction(dir: Vector2):
	direction = dir.normalized()

func _on_body_entered( body: Node):
	if body.is_in_group("enemies"):
		kill_sfx.play()
		emit_signal("enemy_hit", body)
		queue_free()
