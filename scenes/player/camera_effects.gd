extends Node3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var player: CharacterBody3D = $".."

# --- Sway ---
@export var max_sway_angle := 1.75
@export var sway_speed := 15.0
var sway_roll := 0.0
var sway_pitch := 0.0

# --- Breathing ---
var current_breath_speed := 1.0
var current_breath_amplitude := 0.025
var breath_timer := 0.0

# --- Internals ---
var head: Node3D
var camera: Camera3D

func _ready():
	head = %Head
	camera = %Camera3D

func _physics_process(delta):
	# --- SWAY ---
		var lateral_velocity = player.velocity.dot(transform.basis.x)
		var forward_velocity = player.velocity.dot(transform.basis.z)
		if player.state == PlayerState.CROUCHING:
			lateral_velocity *= 0.5
			forward_velocity *= 0.5

		sway_roll = lerp(sway_roll, -lateral_velocity / player.run_speed * max_sway_angle, delta * sway_speed)
		sway_pitch = lerp(sway_pitch, -forward_velocity / player.run_speed * max_sway_angle, delta * sway_speed)

		head.rotation.z = deg_to_rad(sway_roll)
		camera.rotation.x = deg_to_rad(player.pitch) + deg_to_rad(sway_pitch)

		# --- BREATHING ---
		var target_breath_speed = 1.0
		var target_breath_amplitude = 0.025
		match player.state:
			PlayerState.IDLE:
				target_breath_speed = 0.6
				target_breath_amplitude = 0.015
			PlayerState.CROUCHING:
				target_breath_speed = 0.4
				target_breath_amplitude = 0.01
			PlayerState.WALKING:
				target_breath_speed = 1.3
				target_breath_amplitude = 0.025
			PlayerState.RUNNING:
				target_breath_speed = 1.9
				target_breath_amplitude = 0.04
			PlayerState.JUMPING:
				target_breath_speed = 2.2
				target_breath_amplitude = 0.055
			PlayerState.ZEROG:
				target_breath_speed = 0.8
				target_breath_amplitude = 0.015

		current_breath_speed = lerp(current_breath_speed, target_breath_speed, delta * 2.0)
		current_breath_amplitude = lerp(current_breath_amplitude, target_breath_amplitude, delta * 2.0)

		breath_timer += delta * current_breath_speed
		var breath_offset = sin(breath_timer * PI * 2.0) * current_breath_amplitude
		var base_head_y = player.current_height - 0.2
		head.position.y = lerp(head.position.y, base_head_y + breath_offset, delta * 5.0)
