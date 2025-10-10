extends CharacterBody3D

# Movement Settings
@export_group("Movement")
@export var walk_speed: float = 3  # Very slow underwater walk
@export var acceleration: float = 2.0  # Sluggish acceleration
@export var friction: float = 3.0  # Water resistance
@export var gravity: float = 4.0  # Reduced gravity underwater
@export var buoyancy: float = 2.0  # Slight upward force

# Mouse Settings
@export_group("Camera")
@export var mouse_sensitivity: float = 0.02
@export var mouse_smoothing: float = 2.0 # Lower = More smoothing
@export var vertical_look_limit: float = 60.0
@export var head_bob_frequency: float = 2.0
@export var head_bob_amplitude: float = 0.055
@export var camera_sway_amount: float = 0.02

# Underwater effects
@export_group("Underwater Effects")
@export var water_drag: float = 0.85  # Velocity dampening per frame
@export var momentum_factor: float = 0.3  # Maintains some momentum
@export var footstep_interval: float = 1.2  # Time between footstep sounds

# Node references
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var footstep_timer: Timer = $FootstepTimer

# Internal variables
var mouse_delta: Vector2 = Vector2.ZERO
var smoothed_mouse_delta: Vector2 = Vector2.ZERO
var camera_rotation: Vector2 = Vector2.ZERO
var head_bob_time: float = 0.0
var is_moving: bool = false
var momentum_velocity: Vector3 = Vector3.ZERO
var sway_velocity: Vector2 = Vector2.ZERO
var original_camera_pos: Vector3


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Setup footstep timer
	footstep_timer.wait_time = footstep_interval
	footstep_timer.timeout.connect(_on_footstep)
	
	# Store original camera position for bobbing
	original_camera_pos = camera.position

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
	rotation.y = camera_rotation.y
	
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
	var breathing = sin(GameVariables.get_time_ms() * 0.001) * 0.005
	camera.position.y += breathing


func _on_footstep() -> void:
	# Timer calls this
	pass

func _get_vision_basis() -> Basis:
	return camera.get_global_transform().basis

func _get_vision_position() -> Vector3:
	return position + camera_pivot.position
