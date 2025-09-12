extends CharacterBody3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var vitals: Node3D = $Vitals

# --- Movement ---
@export var walk_speed := 4.0
@export var run_speed := 7.0
@export var gravity := 12.0
@export var accel := 8.0
@export var decel := 10.0

# --- Jump ---
@export var min_jump_force := 2.0
@export var max_jump_force := 3.0
@export var jump_hold_time := 0.2

# --- Crouch ---
@export var crouch_height := 0.9
@export var stand_height := 1.8
@export var crouch_speed := 2.5

# --- Camera ---
@export var mouse_sens := 0.1
@export var mouse_smooth := 0.5
@export var max_sway_angle := 1.75
@export var sway_speed := 15.0

# --- Breathing ---
var current_breath_speed := 1.0
var current_breath_amplitude := 0.025
var breath_timer := 0.0

# --- Internal ---
var velocity_y := 0.0
var head
var camera
var collision_shape
var ceiling_check
var current_height := 0.0

var yaw := 0.0
var pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0
var sway_roll := 0.0
var sway_pitch := 0.0

var jumping := false
var jump_timer := 0.0

var state := PlayerState.IDLE

func _ready():
	head = $Head
	camera = $Head/Camera3D
	collision_shape = $CollisionShape3D
	ceiling_check = $CeilingCheck
	current_height = stand_height
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		target_yaw -= deg_to_rad(event.relative.x * mouse_sens)
		target_pitch -= deg_to_rad(event.relative.y * mouse_sens)
		target_pitch = clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89))

func _process(_delta):
	# Mouse look smoothing
	yaw = lerp(yaw, target_yaw, mouse_smooth)
	pitch = lerp(pitch, target_pitch, mouse_smooth)
	rotation.y = yaw
	head.rotation.x = pitch

func _physics_process(delta):
	# --- INPUT ---
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var moving = direction.length() > 0.01
	var crouch_pressed = Input.is_action_pressed("crouch")
	var sprint_pressed = Input.is_action_pressed("sprint")

	# --- STATE DETERMINATION ---
	if not is_on_floor():
		state = PlayerState.JUMPING
	elif crouch_pressed or ceiling_check.is_colliding():
		# Tuşa basılıysa veya kafanda tavan varsa CROUCHING
		state = PlayerState.CROUCHING
	elif moving:
		state = PlayerState.RUNNING if sprint_pressed else PlayerState.WALKING
	else:
		state = PlayerState.IDLE

	vitals.apply_fatigue_drain(state, delta)

	# --- SPEED ---
	var speed = walk_speed
	match state:
		PlayerState.RUNNING:
			speed = run_speed
		PlayerState.CROUCHING:
			speed = crouch_speed

	# --- VELOCITY X/Z ---
	var target_velocity = direction * speed
	velocity.x = lerp(velocity.x, target_velocity.x, accel * delta if moving else decel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, accel * delta if moving else decel * delta)

	# --- JUMP ---
	if is_on_floor():
		velocity_y = 0.0
		jumping = false
		jump_timer = 0.0

		if Input.is_action_just_pressed("jump") and state != PlayerState.CROUCHING:
			# sadece CROUCHING değilken zıpla
			velocity_y = min_jump_force
			jumping = true
	else:
		velocity_y -= gravity * delta

	if jumping and Input.is_action_pressed("jump") and jump_timer < jump_hold_time:
		var t = jump_timer / jump_hold_time
		var extra_force = lerp(min_jump_force, max_jump_force, t)
		velocity_y = extra_force
		jump_timer += delta

	velocity.y = velocity_y

	# --- CROUCH HEIGHT & HEAD POSITION ---
	var target_height = stand_height if state != PlayerState.CROUCHING else crouch_height
	current_height = lerp(current_height, target_height, delta * 10.0)
	collision_shape.shape.height = current_height
	collision_shape.position.y = current_height / 2.0

	var target_head_pos = Vector3(0, 1.6, 0) if state != PlayerState.CROUCHING else Vector3(0, 0.9, 0)
	head.position = head.position.lerp(target_head_pos, delta * 10.0)

	# --- SWAY ---
	var lateral_velocity = velocity.dot(transform.basis.x)
	var forward_velocity = velocity.dot(transform.basis.z)
	if state == PlayerState.CROUCHING:
		lateral_velocity *= 0.5
		forward_velocity *= 0.5

	sway_roll = lerp(sway_roll, lateral_velocity / run_speed * max_sway_angle, delta * sway_speed)
	sway_pitch = lerp(sway_pitch, forward_velocity / run_speed * max_sway_angle, delta * sway_speed)

	head.rotation.z = deg_to_rad(sway_roll)
	camera.rotation.x = deg_to_rad(pitch) + deg_to_rad(sway_pitch)

	# --- BREATHING ---
	var target_breath_speed = 1.0
	var target_breath_amplitude = 0.025
	match state:
		PlayerState.IDLE:
			target_breath_speed = 0.9
			target_breath_amplitude = 0.02
		PlayerState.CROUCHING:
			target_breath_speed = 0.7
			target_breath_amplitude = 0.015
		PlayerState.WALKING:
			target_breath_speed = 1.2
			target_breath_amplitude = 0.03
		PlayerState.RUNNING:
			target_breath_speed = 2.0
			target_breath_amplitude = 0.05
		PlayerState.JUMPING:
			target_breath_speed = 1.8
			target_breath_amplitude = 0.04

	current_breath_speed = lerp(current_breath_speed, target_breath_speed, delta * 2.0)
	current_breath_amplitude = lerp(current_breath_amplitude, target_breath_amplitude, delta * 2.0)

	breath_timer += delta * current_breath_speed
	var breath_offset = sin(breath_timer * PI * 2.0) * current_breath_amplitude
	var base_head_y = current_height - 0.2
	head.position.y = lerp(head.position.y, base_head_y + breath_offset, delta * 5.0)

	# --- MOVE ---
	move_and_slide()
