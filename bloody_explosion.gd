extends Node2D

@onready var particles = $GPUParticles2D

func _ready():
	particles.restart()
	await get_tree().create_timer(particles.lifetime + 0.5).timeout
	queue_free()
