extends Node2D

@export var cleanup_time := 10.0
@export var trail_color := Color(0.6, 0.6, 0.0, 0.8)
var PeeTrail = preload("res://pee_trail.tscn")
@onready var sprite := $Sprite2D

func _ready():
	sprite.modulate = trail_color
	await get_tree().create_timer(cleanup_time).timeout
	queue_free()
