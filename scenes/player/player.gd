extends CharacterBody3D

const PlayerState = preload("res://scenes/player/player_states.gd").PlayerState

@onready var vitals: Node3D = $Vitals
@onready var head: Node3D = %Head

# --- Movement ---
@export var walk_speed := 4.0
@export var run_speed := 6.5
@export var gravity := 12.0
@export var accel := 8.0
@export var decel := 10.0
@export var air_control := 0.5

# --- Jump ---
@export var min_jump_force := 2.0
@export var max_jump_force := 3.0
@export var jump_hold_time := 0.2
@export var coyote_time := 0.15

# --- Crouch ---
@export var crouch_height := 0.9
@export var stand_height := 1.8
@export var crouch_speed := 2.5

# --- Thruster ---
@export var thruster_force := 3.0
@export var thruster_boost_force := 7.0
@export var thruster_oxygen_rate := 0.8
@export var thruster_boost_oxygen_rate := 3.8

# --- Camera ---
@export var mouse_sens := 0.1
@export var mouse_smooth := 0.5
@export var max_sway_angle := 1.75
@export var sway_speed := 15.0

# --- Internal ---
var velocity_y := 0.0
var collision_shape
var ceiling_check
var current_height := 0.0
var is_in_space := false

var yaw := 0.0
var pitch := 0.0
var target_yaw := 0.0
var target_pitch := 0.0

var jumping := false
var jump_timer := 0.0
var falling_start_y := 0.0
var is_falling := false
var coyote_timer := 0.0

var state := PlayerState.IDLE


func _ready():
	collision_shape = $CollisionShape3D
	ceiling_check = $CeilingCheck
	current_height = stand_height
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	var input = handle_input()

	state = determine_state(input)

	if state == PlayerState.ZEROG:
		handle_zero_g(input, delta)
	else:
		vitals.apply_fatigue_drain(state, delta)
		handle_movement(input, delta)
		handle_jump(input, delta)
		update_crouch_height(delta)

	applyCamSmoothing(delta)
	move_and_slide()


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		target_yaw -= deg_to_rad(event.relative.x * mouse_sens)
		target_pitch -= deg_to_rad(event.relative.y * mouse_sens)
		target_pitch = clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89))
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()


func applyCamSmoothing(_delta) -> void:
	yaw = lerp(yaw, target_yaw, mouse_smooth)
	pitch = lerp(pitch, target_pitch, mouse_smooth)
	rotation.y = yaw
	head.rotation.x = pitch


func handle_input() -> Dictionary:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	var cam_forward = head.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	var cam_right = head.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var direction = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	return {
		"direction": direction,
		"moving": direction.length() > 0.01,
		"crouch": Input.is_action_pressed("crouch"),
		"sprint": Input.is_action_pressed("sprint"),
		"jump": Input.is_action_pressed("jump"),
		"jump_pressed": Input.is_action_just_pressed("jump"),
	}


func determine_state(input: Dictionary) -> PlayerState:
	if is_in_space:
		return PlayerState.ZEROG
	if not is_on_floor():
		if velocity_y < 0 or ceiling_check.is_colliding():
			if not is_falling:
				is_falling = true
				falling_start_y = global_transform.origin.y
			return PlayerState.FALLING
		else:
			return PlayerState.JUMPING
	elif input["crouch"] or (ceiling_check.is_colliding() and is_on_floor()):
		return PlayerState.CROUCHING
	elif input["moving"]:
		return PlayerState.RUNNING if input["sprint"] else PlayerState.WALKING
	else:
		return PlayerState.IDLE


# --- ZERO-G MOVEMENT ---
func handle_zero_g(input: Dictionary, delta: float):
	var forward_dir = -head.global_transform.basis.z
	var right_dir = head.global_transform.basis.x
	var up_dir = Vector3.UP

	var thrust = Vector3.ZERO
	thrust += forward_dir * (1 if Input.is_action_pressed("move_forward") else 0)
	thrust -= forward_dir * (1 if Input.is_action_pressed("move_back") else 0)
	thrust += right_dir * (1 if Input.is_action_pressed("move_right") else 0)
	thrust -= right_dir * (1 if Input.is_action_pressed("move_left") else 0)
	thrust += up_dir * (1 if Input.is_action_pressed("jump") else 0)
	thrust -= up_dir * (1 if Input.is_action_pressed("crouch") else 0)

	var sprinting = input["sprint"]
	var speed = thruster_boost_force if sprinting else thruster_force
	var oxygen_needed = (thruster_boost_oxygen_rate if sprinting else thruster_oxygen_rate) * delta

	if thrust.length() > 0.01:
		var oxygen_used = vitals.use_oxygen(oxygen_needed)
		if oxygen_used > 0.0:
			var target_velocity = thrust.normalized() * speed
			velocity = velocity.lerp(target_velocity, delta * 3.5)
	else:
		velocity *= pow(0.85, delta * 2.5)

	if velocity.length() > speed:
		velocity = velocity.normalized() * speed


# --- NORMAL MOVEMENT ---
func handle_movement(input: Dictionary, delta: float):
	var speed = walk_speed
	match state:
		PlayerState.RUNNING:
			speed = run_speed
		PlayerState.CROUCHING:
			speed = crouch_speed
		PlayerState.JUMPING, PlayerState.FALLING:
			speed = run_speed if input["sprint"] else walk_speed

	var target_velocity = input["direction"] * speed

	var current_accel = accel if input["moving"] else decel
	if not is_on_floor():
		current_accel *= air_control  # havadayken daha az hızlanma

	velocity.x = lerp(velocity.x, target_velocity.x, current_accel * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, current_accel * delta)


# --- JUMP ---
func handle_jump(input: Dictionary, delta: float):
	# COYOTE TIMER
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	# Fall damage control
	if is_on_floor():
		if is_falling:
			handle_fall_damage()
		velocity_y = 0.0
		jumping = false
		jump_timer = 0.0

	# Jump input and coyote time
	if (input["jump_pressed"] and coyote_timer > 0.0 and state != PlayerState.CROUCHING):
		velocity_y = min_jump_force
		jumping = true
		coyote_timer = 0.0
	
	# Ceiling check
	if ceiling_check.is_colliding() and velocity_y > 0:
		velocity_y = 0.0
		jumping = false
		is_falling = true
		falling_start_y = global_transform.origin.y

	# Gravity
	if not is_on_floor():
		velocity_y -= gravity * delta

	# Jump hold
	if jumping:
		if input["jump"] and jump_timer < jump_hold_time and not ceiling_check.is_colliding():
			var t = jump_timer / jump_hold_time
			var jump_strength = min_jump_force + (max_jump_force - min_jump_force) * sin(t * PI / 2)
			velocity_y = jump_strength
			jump_timer += delta
		else:
			jumping = false

	velocity.y = velocity_y


func handle_fall_damage():
	var fall_distance = falling_start_y - global_transform.origin.y
	if fall_distance > 3.0:
		var fall_damage = (fall_distance - 3.0) * 10.0
		vitals.damage_health(fall_damage, 1.0)
	is_falling = false


func update_crouch_height(delta: float):
	var target_height = stand_height if state != PlayerState.CROUCHING else crouch_height
	current_height = lerp(current_height, target_height, delta * 9.0)
	collision_shape.shape.height = current_height
	collision_shape.position.y = current_height / 2.0

	var target_head_pos = Vector3(0, 1.6, 0) if state != PlayerState.CROUCHING else Vector3(0, 0.9, 0)
	head.position = head.position.lerp(target_head_pos, delta * 9.0)


func _on_portal_entered(_player) -> void:
	is_in_space = false

func _on_portal_exited(_player) -> void:
	is_in_space = true
