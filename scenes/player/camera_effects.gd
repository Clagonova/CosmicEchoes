extends Node3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var player: CharacterBody3D = $".."
@onready var head: Node3D = %Head
@onready var eyes: Node3D = %Eyes

# --- Sway ---
@export var max_sway_angle := 1.75
@export var sway_stiffness := 120.0
@export var sway_damping := 15.0

var sway_roll := 0.0
var sway_pitch := 0.0
var sway_roll_vel := 0.0
var sway_pitch_vel := 0.0

# --- Breathing ---
var base_breath_speed := 1.0
var base_breath_amplitude := 0.025
var breath_timer := 0.0
	
# Manuel ayarlama için override değerleri
var manual_breath_override := false
var manual_breath_speed := 1.0
var manual_breath_amplitude := 0.025


func spring_update(current: float, target: float, velocity: float, delta: float, stiffness := 120.0, damping := 15.0) -> Array:
	var displacement = target - current
	var spring_force = displacement * stiffness
	var damping_force = -velocity * damping
	var force = spring_force + damping_force

	velocity += force * delta
	current += velocity * delta
	return [current, velocity]

func set_manual_breath(speed: float, amplitude: float, duration: float = 0.0) -> void:
	manual_breath_override = true
	manual_breath_speed = speed
	manual_breath_amplitude = amplitude

	if duration > 0.0:
		var t = Timer.new()
		t.wait_time = duration
		t.one_shot = true
		add_child(t)
		t.start()
		await t.timeout
		manual_breath_override = false
		t.queue_free()


func _physics_process(delta):
	# --- SWAY ---
	var local_velocity = player.global_transform.affine_inverse() * player.velocity
	var lateral_velocity = local_velocity.x
	var forward_velocity = local_velocity.z

	var state_sway_factor = 1.0
	match player.state:
		PlayerState.CROUCHING:
			lateral_velocity *= 0.5
			forward_velocity *= 0.5
			state_sway_factor = 0.6
		PlayerState.WALKING:
			state_sway_factor = 0.8
		PlayerState.RUNNING:
			state_sway_factor = 1.2
		PlayerState.JUMPING:
			state_sway_factor = 1.0
		PlayerState.ZEROG:
			state_sway_factor = 0.4

	var target_roll = (-lateral_velocity / player.run_speed) * max_sway_angle * state_sway_factor
	var target_pitch = (-forward_velocity / player.run_speed) * max_sway_angle * state_sway_factor

	var res_roll = spring_update(sway_roll, target_roll, sway_roll_vel, delta, sway_stiffness, sway_damping)
	sway_roll = res_roll[0]
	sway_roll_vel = res_roll[1]

	var res_pitch = spring_update(sway_pitch, target_pitch, sway_pitch_vel, delta, sway_stiffness, sway_damping)
	sway_pitch = res_pitch[0]
	sway_pitch_vel = res_pitch[1]
	
	head.rotation.z = deg_to_rad(sway_roll)
	eyes.rotation.x = deg_to_rad(player.pitch) + deg_to_rad(sway_pitch)

	# --- BREATHING ---
	var target_breath_speed := base_breath_speed
	var target_breath_amplitude := base_breath_amplitude

	if manual_breath_override:
		target_breath_speed = manual_breath_speed
		target_breath_amplitude = manual_breath_amplitude
	else:
		var speed_factor = player.velocity.length() / player.run_speed
		speed_factor = clamp(speed_factor, 0.0, 1.0)

		match player.state:
			PlayerState.IDLE:
				target_breath_speed = lerp(0.6, 1.0, speed_factor)
				target_breath_amplitude = lerp(0.015, 0.025, speed_factor)
			PlayerState.CROUCHING:
				target_breath_speed = lerp(0.4, 0.8, speed_factor)
				target_breath_amplitude = lerp(0.01, 0.02, speed_factor)
			PlayerState.WALKING:
				target_breath_speed = lerp(1.0, 1.3, speed_factor)
				target_breath_amplitude = lerp(0.02, 0.03, speed_factor)
			PlayerState.RUNNING:
				target_breath_speed = lerp(1.3, 1.9, speed_factor)
				target_breath_amplitude = lerp(0.03, 0.04, speed_factor)
			PlayerState.JUMPING:
				target_breath_speed = lerp(1.5, 2.2, speed_factor)
				target_breath_amplitude = lerp(0.04, 0.055, speed_factor)
			PlayerState.ZEROG:
				target_breath_speed = lerp(0.7, 1.0, speed_factor)
				target_breath_amplitude = lerp(0.01, 0.02, speed_factor)

	var lerp_up_speed := 5.0
	var lerp_down_speed := 1.0

	if base_breath_speed < target_breath_speed:
		base_breath_speed = lerp(base_breath_speed, target_breath_speed, delta * lerp_up_speed)
	else:
		base_breath_speed = lerp(base_breath_speed, target_breath_speed, delta * lerp_down_speed)

	if base_breath_amplitude < target_breath_amplitude:
		base_breath_amplitude = lerp(base_breath_amplitude, target_breath_amplitude, delta * lerp_up_speed)
	else:
		base_breath_amplitude = lerp(base_breath_amplitude, target_breath_amplitude, delta * lerp_down_speed)

	breath_timer += delta * base_breath_speed
	var breath_offset = sin(breath_timer * PI * 2.0) * base_breath_amplitude
	var base_head_y = player.current_height - 0.2
	head.position.y = lerp(head.position.y, base_head_y + breath_offset, delta * 5.0)
