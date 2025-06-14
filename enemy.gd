extends CharacterBody2D

@export var speed := 100.0

var player_ref: Node = null

func set_player(player: Node) -> void:
	player_ref = player

func _physics_process(_delta):
	if not player_ref:
		return

	var dir = (player_ref.global_position - global_position).normalized()
	velocity = dir * speed
	move_and_slide()

	rotation = dir.angle() + PI / 2

func _on_hit():
	queue_free()

func _ready():
	add_to_group("enemies")
