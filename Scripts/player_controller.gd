extends CharacterBody3D

signal velocity_updated
signal player_half_oxygen
signal player_almost_no_oxygen
signal player_out_of_oxygen

# Movement Settings
@export_group("Movement")
@export var walk_speed: float = 10.0  # Very slow underwater walk
@export var acceleration: float = 2.0  # Sluggish acceleration
@export var friction: float = 3.0  # Water resistance
@export var gravity: float = 4.0  # Reduced gravity underwater
@export var buoyancy: float = 0.5  # Slight upward force

# Mouse Settings
@export_group("Camera")
@export var mouse_sensitivity: float = 0.02
@export var mouse_smoothing: float = 2.0 # Lower = More smoothing
@export var vertical_look_limit: float = 60.0
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.075
@export var camera_sway_amount: float = 0.02

# Underwater effects
@export_group("Underwater Effects")
@export var water_drag: float = 0.85  # Velocity dampening per frame
@export var momentum_factor: float = 0.3  # Maintains some momentum
@export var footstep_interval: float = 1.2  # Time between footstep sounds

# Movement limitation
@export_group("Movement Limitation")
@export var maximal_distance_anchor: float
@export var anchor: Node3D
@export var alpha_tolerance: float = 0.15
@onready var tolerance: float = cos(alpha_tolerance)

# Bubble updates settings
@export_group("Bubbles Settings")
@export var time_between_velocity_updates_for_bubbles: float = 0.2

# Breathing animation settings
@export_group("Breathing Animation")
@export var breathing_animation_amplitude: float =  0.02
var breathing_animation_pulsation: float
var breathing_animation_phase: float

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var footstep_timer: Timer = $FootstepTimer
@onready var flashlight: SpotLight3D = $CameraPivot/SpotLight3D
@onready var flashlight_on_sound: AudioStreamPlayer = $CameraPivot/SpotLight3D/FlashlightToggleOn
@onready var flashlight_off_sound: AudioStreamPlayer = $CameraPivot/SpotLight3D/FlashlightToggleOff
@onready var footstep_sound: AudioStreamPlayer = $FootstepTimer/FootstepSound
@onready var breathing_controller: Node = $BreathingController
@onready var oxygen_controller: Node = $OxygenController
@onready var on_collider_timer: Timer

# Internal variables
var mouse_delta: Vector2 = Vector2.ZERO
var smoothed_mouse_delta: Vector2 = Vector2.ZERO
var camera_rotation: Vector2 = Vector2.ZERO
var head_bob_time: float = 0.0
var is_moving: bool = false
var momentum_velocity: Vector3 = Vector3.ZERO
var sway_velocity: Vector2 = Vector2.ZERO
var original_camera_pos: Vector3
var initial_rotation: float = 0.0

func _ready() -> void:
	collision_layer = 0b00000000_00000000_00000000_00000001
	collision_mask = 0b00000000_00000000_00000000_00000110
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup footstep timer
	footstep_timer.wait_time = footstep_interval
	footstep_timer.timeout.connect(_on_footstep)
	
	# Store original camera position for bobbing
	original_camera_pos = camera.position

	# Store initial rotation
	initial_rotation = rotation.y

	# send velocity message for bubbles
	var velocity_timer: Timer = Timer.new()
	velocity_timer.timeout.connect(_on_velocity_timer_timeout)
	velocity_timer.one_shot = false
	add_child(velocity_timer)
	velocity_timer.start(time_between_velocity_updates_for_bubbles)

	# handle breathing animation
	breathing_controller.exhaled.connect(_on_exhaled)
	breathing_controller.inhaled.connect(_on_inhaled)
	
	# handle game over
	oxygen_controller.half_oxygen.connect(_on_player_half_oxygen)
	oxygen_controller.almost_no_oxygen.connect(_on_player_almost_no_oxygen)
	oxygen_controller.out_of_oxygen.connect(_on_player_out_of_oxygen)

func _input(event: InputEvent) -> void:
	# Handle mouse input
	if event is InputEventMouseMotion:
		mouse_delta = event.relative
	
	# Toggle mouse capture with ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Auto-recapture when clicking in the window
	if event is InputEventMouseButton:
		if event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_F:
			if flashlight.visible:
				flashlight.visible = false
				flashlight_off_sound.play()
			else:
				flashlight.visible = true
				flashlight_on_sound.play()

func _physics_process(delta: float) -> void:
	# Only process if mouse is captured
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	
	_handle_mouse_look(delta)
	_handle_movement(delta)
	_apply_underwater_effects(delta)
	_update_camera_effects(delta)
	move_and_slide()

func _handle_mouse_look(delta: float) -> void:
	# Apply heavy smoothing to mouse input
	smoothed_mouse_delta = smoothed_mouse_delta.lerp(mouse_delta, delta * mouse_smoothing)
	
	# Apply rotation with sensitivity
	camera_rotation.x -= smoothed_mouse_delta.y * mouse_sensitivity
	camera_rotation.y -= smoothed_mouse_delta.x * mouse_sensitivity
	
	# Clamp vertical rotation (limited by helmet)
	camera_rotation.x = clamp(camera_rotation.x, -deg_to_rad(vertical_look_limit), deg_to_rad(vertical_look_limit))
	
	# Apply rotations
	camera_pivot.rotation.x = camera_rotation.x
	rotation.y = camera_rotation.y + initial_rotation
	
	# Add slight sway from rotation (helmet inertia)
	var sway_target = Vector2(smoothed_mouse_delta.x * camera_sway_amount, smoothed_mouse_delta.y * camera_sway_amount)
	sway_velocity = sway_velocity.lerp(sway_target, delta * 3.0)
	camera.rotation.z = sway_velocity.x * 0.5
	camera.rotation.x = sway_velocity.y * 0.3
	
	# Reset mouse delta
	mouse_delta = Vector2.ZERO

func _handle_movement(delta: float) -> void:
	# Get input direction
	var input_dir = Vector2()
	input_dir.x = Input.get_axis("move_left", "move_right")
	input_dir.y = Input.get_axis("move_forward", "move_backward")
	
	# Get movement direction in world space
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Track if moving for effects
	is_moving = direction.length() > 0.1
	
	if is_moving:
		
		# check which direction are allowed if too far from anchor
		if anchor != null:
			var distance_anchor = position.distance_to(anchor.position)
			if distance_anchor > maximal_distance_anchor:
				var anchor_player_vector = position - anchor.position
				anchor_player_vector.y = 0
				var normal_vector = anchor_player_vector.normalized()
				var dot = direction.dot(normal_vector)

				if dot + tolerance > 0:
					# remove outward component and tangeantial movement with a set angle
					direction = direction - normal_vector * (dot + tolerance)
					direction.y = 0
					direction = direction.normalized()

		# Apply heavy acceleration with momentum
		var target_velocity = direction * walk_speed
		momentum_velocity = momentum_velocity.lerp(target_velocity, delta * acceleration)
		velocity.x = momentum_velocity.x
		velocity.z = momentum_velocity.z
		
		# Start footstep timer if not running
		if footstep_timer.is_stopped():
			footstep_timer.start()
	else:
		# Apply friction when not moving
		momentum_velocity = momentum_velocity.lerp(Vector3.ZERO, delta * friction)
		velocity.x = momentum_velocity.x
		velocity.z = momentum_velocity.z
		
		# Stop footstep timer
		footstep_timer.stop()
	
	# Apply gravity with buoyancy
	if not is_on_floor():
		velocity.y -= (gravity - buoyancy) * delta
	else:
		# Small ground adhesion
		if velocity.y < 0:
			velocity.y = -0.1


func _apply_underwater_effects(_delta: float) -> void:
	# Apply water drag to all movement
	velocity *= water_drag
	momentum_velocity *= water_drag
	
	# Add slight drift/current effect (optional)
	# velocity.x += sin(Time.get_ticks_msec() * 0.0005) * 0.05
	
	# Limit maximum velocity (water resistance)
	var horizontal_vel = Vector2(velocity.x, velocity.z)
	if horizontal_vel.length() > walk_speed * 1.2:
		horizontal_vel = horizontal_vel.normalized() * walk_speed * 1.2
		velocity.x = horizontal_vel.x
		velocity.z = horizontal_vel.y


func _update_camera_effects(delta: float) -> void:
	# Head bobbing while walking
	if is_moving and is_on_floor():
		head_bob_time += delta * head_bob_frequency
		
		# Figure-8 pattern for realistic bob
		var bob_offset = Vector3()
		bob_offset.y = sin(head_bob_time * 2.0) * head_bob_amplitude
		bob_offset.x = sin(head_bob_time) * head_bob_amplitude * 0.5
		
		camera.position = original_camera_pos + bob_offset
	else:
		# Return to original position slowly
		camera.position = camera.position.lerp(original_camera_pos, delta * 2.0)
		head_bob_time = 0.0

	# Add subtle breathing motion even when still
	var breathing = breathing_animation(GameVariables.get_time_s())
	camera.position.y += breathing

func breathing_animation(t: float) -> float:
	if breathing_animation_pulsation != null and breathing_animation_phase != null:
		return sin(t * breathing_animation_pulsation + breathing_animation_phase) * breathing_animation_amplitude
	return 0.0

func _on_exhaled() -> void:
	breathing_animation_pulsation = PI / (breathing_controller.time_after_exhaling * 1000.0)
	breathing_animation_phase = - PI/ 2 - breathing_animation_pulsation * GameVariables.get_time_s()

func _on_inhaled() -> void:
	breathing_animation_pulsation = PI / breathing_controller.time_after_inhaling
	breathing_animation_phase = PI/ 2 - breathing_animation_pulsation * GameVariables.get_time_s()

func _on_velocity_timer_timeout() -> void:
	velocity_updated.emit(velocity)

func _on_footstep() -> void:
	if is_on_floor():
		footstep_sound.play()

func _get_vision_basis() -> Basis:
	return camera.get_global_transform().basis

func _get_vision_position() -> Vector3:
	return position + camera_pivot.position

func _on_player_half_oxygen() -> void:
	player_half_oxygen.emit()

func _on_player_almost_no_oxygen() -> void:
	player_almost_no_oxygen.emit()

func _on_player_out_of_oxygen() -> void:
	player_out_of_oxygen.emit()
