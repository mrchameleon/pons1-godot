extends Node2D

@onready var blood = $GPUParticles2D

func _ready():
	blood.restart()
	await get_tree().create_timer(blood.lifetime + 0.5).timeout
	queue_free()
