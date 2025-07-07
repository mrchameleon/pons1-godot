extends CanvasLayer

@onready var powerup_interval_input: LineEdit = $VBoxContainer/powerup_interval/powerup_interval_input
@onready var wave_interval_input: LineEdit = $VBoxContainer/wave_interval/wave_interval_input
@onready var base_enemy_count_input: LineEdit = $VBoxContainer/base_enemy_count/base_enemy_count_input
@onready var base_enemy_speed_input: LineEdit = $VBoxContainer/base_enemy_speed/base_enemy_speed_input
@onready var speed_increase_per_wave_input: LineEdit = $VBoxContainer/speed_increase_per_wave/speed_increase_per_wave_input

signal settings_applied()

func _ready():
	powerup_interval_input.text = str(Globals.powerup_spawn_interval)
	wave_interval_input.text = str(Globals.wave_interval)
	base_enemy_count_input.text = str(Globals.base_enemy_count)
	base_enemy_speed_input.text = str(Globals.base_enemy_speed)
	speed_increase_per_wave_input.text = str(Globals.speed_increase_per_wave)
	
func _on_apply_pressed() -> void:
	Globals.powerup_spawn_interval = powerup_interval_input.text.to_float()
	Globals.wave_interval = wave_interval_input.text.to_float()
	Globals.base_enemy_count = base_enemy_count_input.text.to_int()
	Globals.base_enemy_speed = base_enemy_speed_input.text.to_float()
	Globals.speed_increase_per_wave = speed_increase_per_wave_input.text.to_float()
	emit_signal("settings_applied")
