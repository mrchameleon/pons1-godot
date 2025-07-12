extends Node

var player = null
var joystick_pee_suppress = false
var pee_aim_pressed = false
var powerups_used = 0

var pee_container_max = 5000.0
var pee_regen_rate = 300
var pee_regen_during_shoot = 100
var pee_cost_per_shot = 25

var base_pee_speed := 180.0
var base_pee_life := 1 # seconds
var powerup_pee_speed_modifier := 5
var powerup_pee_lifetime_modifier := 0.2


var def_powerup_spawn_interval := 10
var def_wave_interval := 6
var def_base_enemy_count := 2
var def_base_enemy_speed := 100
var def_speed_increase_per_wave := 2

var powerup_spawn_interval = def_powerup_spawn_interval
var wave_interval = def_wave_interval
var base_enemy_count = def_base_enemy_count
var base_enemy_speed = def_base_enemy_speed
var speed_increase_per_wave =def_speed_increase_per_wave
