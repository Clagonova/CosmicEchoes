extends Node3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var player: CharacterBody3D = $".."
@onready var head: Node3D = %Head
@onready var eyes: Node3D = %Eyes

# --- Head sway / lean ---
var sway_amount := 0.05
var sway_speed := 15.0

# --- Breathing ---
var base_breath_speed := 1.0
var base_breath_amplitude := 0.025
var breath_timer := 0.0
	
# Manuel override values
var manual_breath_override := false
var manual_breath_speed := 1.0
var manual_breath_amplitude := 0.025


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
	# --- HEAD SWAY ---
	var local_velocity = head.global_transform.basis.inverse() * player.velocity
	var target_tilt = 0.0

	if local_velocity.length() > 0.1:
		target_tilt = clamp(-local_velocity.x / player.run_speed * sway_amount, -sway_amount, sway_amount)

	var current_rot = head.rotation
	current_rot.z = lerp(current_rot.z, target_tilt, delta * sway_speed)
	head.rotation = current_rot
	
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
