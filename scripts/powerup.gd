extends Area2D

var color
var effect
var texture

const COLORS = ["blue", "green", "yellow", "purple", "orange"]
const EFFECTS = ["rate_up", "distance_up", "player_speed_up"]

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var pickup_label: Label = $Label


func show_pickup_message(text: String):
	pickup_label.text = text
	pickup_label.modulate.a = 1.0
	pickup_label.position = Vector2(0, -24)  # just above the power-up

	var tween = create_tween()
	tween.tween_property(pickup_label, "position:y", pickup_label.position.y - 20, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(pickup_label, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tween.tween_callback(Callable(self, "_hide_pickup_label"))

func _ready():
	color = COLORS.pick_random()
	match color:
		"orange":
			texture = preload("res://images/powerup_orange.png")
			pickup_label.text = "Dr. Pee Pee"
		"yellow":
			texture = preload("res://images/powerup_yellow.png")
			pickup_label.text = "Yellow Bull"
		"green":
			texture = preload("res://images/powerup_green.png")
			pickup_label.text = "Baja Blast"
		"purple":
			texture = preload("res://images/powerup_purple.png")
			pickup_label.text = "Purple Pebis"
		"blue":
			texture = preload("res://images/water.png")
			pickup_label.text = "h2o"

	sprite_2d.texture = texture
	effect = EFFECTS.pick_random()
	add_to_group("items")
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		sprite_2d.visible = false
		if body.has_method("apply_powerup"):
			body.apply_powerup(effect, color)
			if effect == "rate_up":
				show_pickup_message("PEE SPEED UP!")
			if effect == "distance_up":
				show_pickup_message("PEE DISTANCE UP!")
			if effect == "player_speed_up":
				show_pickup_message("PLAYER SPEED UP!")
		await get_tree().create_timer(0.6).timeout
		queue_free()
