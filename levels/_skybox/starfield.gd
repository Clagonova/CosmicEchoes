extends MultiMeshInstance3D

@export var star_count: int = 3000
@export var star_radius: float = 1000.0
@export var min_size: float = 2.5
@export var max_size: float = 5.5

@export var shooting_cooldown := 30.0
@export var shooting_duration: float = 3.0
@export var shooting_speed: float = 150.0
@export var shooting_chance: float = 0.2  # 20% chance
@export var shooting_scale_multiplier := 1.5  # kayarken boyut çarpanı

@export var flare_chance := 0.001
@export var flare_min_duration := 0.1
@export var flare_max_duration := 0.3
@export var flare_strength := 1.0

@export var twinkle_strength := 0.7

var base_colors: Array = []
var shooting_timers: Array = []
var shooting_dirs: Array = []
var original_positions: Array = []
var fading_to_black: Array = []
var base_scales: Array = []

var twinkle_phases: Array = []
var twinkle_speeds: Array = []

var flare_timers: Array = []
var flare_durations: Array = []

var time_since_last_shoot := 0.0
var elapsed_time := 0.0

func _ready():
	randomize()
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = SphereMesh.new()
	mm.mesh.radial_segments = 6
	mm.mesh.rings = 2
	mm.use_colors = true
	mm.instance_count = star_count
	self.multimesh = mm

	base_colors.resize(star_count)
	shooting_timers.resize(star_count)
	shooting_dirs.resize(star_count)
	original_positions.resize(star_count)
	fading_to_black.resize(star_count)
	base_scales.resize(star_count)
	twinkle_phases.resize(star_count)
	twinkle_speeds.resize(star_count)
	flare_timers.resize(star_count)
	flare_durations.resize(star_count)

	for i in range(star_count):
		var pos = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized() * star_radius
		var s = randf_range(min_size, max_size)
		var t = Transform3D(Basis().scaled(Vector3.ONE * s), pos)
		mm.set_instance_transform(i, t)
		base_scales[i] = s

		var min_val = 0.2
		var max_val = 1.0
		var val = lerp(min_val, max_val, pow(randf(), 6))
		var r_color = randf()
		var col: Color
		if r_color < 0.8:
			col = Color8(255, 255, 255)
		elif r_color < 0.85:
			col = Color8(183, 40, 46)
		elif r_color < 0.9:
			col = Color8(75, 154, 35)
		elif r_color < 0.95:
			col = Color8(244, 140, 66)
		else:
			col = Color8(100, 54, 143)
		col *= val
		mm.set_instance_color(i, col)
		
		base_colors[i] = col
		shooting_timers[i] = 0.0
		shooting_dirs[i] = Vector3.ZERO
		original_positions[i] = pos
		fading_to_black[i] = false

		twinkle_phases[i] = randf() * PI * 2.0
		twinkle_speeds[i] = randf_range(0.5, 1.5)

		flare_timers[i] = 0.0
		flare_durations[i] = 0.0

func _process(delta):
	var mm = self.multimesh
	time_since_last_shoot += delta
	elapsed_time += delta

	# Shooting star kontrolü
	if time_since_last_shoot >= shooting_cooldown:
		time_since_last_shoot = 0.0
		if randf() < shooting_chance:
			var stars_to_shoot = randi_range(1,2)
			for i in range(stars_to_shoot):
				var idx = randi() % star_count
				if shooting_timers[idx] <= 0.0:
					shooting_timers[idx] = shooting_duration
					shooting_dirs[idx] = Vector3(randf_range(-1,1), randf_range(-0.3,0.3), randf_range(-1,1)).normalized()
					fading_to_black[idx] = false

	for i in range(star_count):
		var t = mm.get_instance_transform(i)
		var brightness = 1.0
		var star_scale = base_scales[i]

		# Shooting star hareketi
		if shooting_timers[i] > 0.0:
			shooting_timers[i] -= delta
			t.origin += shooting_dirs[i] * shooting_speed * delta
			# Boyut artır
			star_scale = base_scales[i] * (1.0 + (shooting_scale_multiplier - 1.0) * min(shooting_timers[i]/shooting_duration,1.0))
			t.basis = Basis().scaled(Vector3.ONE * star_scale)
			mm.set_instance_transform(i, t)
			# Rengini ayarla
			if shooting_timers[i] < shooting_duration * 0.2:
				var factor = shooting_timers[i] / (shooting_duration * 0.2)
				factor = pow(factor, 2)
				brightness *= factor
				fading_to_black[i] = true
			else:
				brightness *= 2.5
		else:
			t.origin = original_positions[i]
			t.basis = Basis().scaled(Vector3.ONE * base_scales[i])
			mm.set_instance_transform(i, t)
			if fading_to_black[i]:
				var col = mm.get_instance_color(i)
				col = col.lerp(base_colors[i], delta * 2.0)
				mm.set_instance_color(i, col)
				var diff = abs(col.r - base_colors[i].r) + abs(col.g - base_colors[i].g) + abs(col.b - base_colors[i].b)
				if diff < 0.01:
					fading_to_black[i] = false

		# Twinkle
		brightness += sin(elapsed_time * twinkle_speeds[i] + twinkle_phases[i]) * twinkle_strength
		brightness *= randf_range(0.85, 1.15)

		# Flare
		if flare_timers[i] <= 0.0 and randf() < flare_chance:
			flare_durations[i] = randf_range(flare_min_duration, flare_max_duration)
			flare_timers[i] = flare_durations[i]
		if flare_timers[i] > 0.0:
			flare_timers[i] -= delta
			var flare_factor = sin((1.0 - flare_timers[i] / flare_durations[i]) * PI) * flare_strength
			brightness += flare_factor

		# Son renk uygula
		mm.set_instance_color(i, base_colors[i] * brightness)
