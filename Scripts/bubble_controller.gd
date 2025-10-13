extends MeshInstance3D

@export var bubble_lifetime: float = 6.0
@export var free_rising_velocity: float = 0.29
@export var helix_frequency: float = 7.0
@export var helix_amplitude: float = 0.004

var helix_pulsation: float
var player_velocity: Vector3
var spawned_time: float
var flow_velocity: Vector3
var bubble_radius: float = 0.015
var excess_velocity: Vector3
@export var follow_time: float = 2.0

@onready var killer_timer = $KillerTimer

func _ready() -> void:
	killer_timer.start(bubble_lifetime)
	killer_timer.timeout.connect(_on_kill)
	mesh.radius = bubble_radius
	mesh.height = 2 * bubble_radius
	
	helix_pulsation = helix_frequency / 2.0 * PI
	spawned_time = Time.get_ticks_msec() / 1000.0

func _process(delta: float) -> void:
	flow_velocity = helix_velocity(free_rising_velocity, helix_amplitude, helix_pulsation)
	var time_since_spawn: float = Time.get_ticks_msec() / 1000.0 - spawned_time
	if time_since_spawn < follow_time:
		var drag_coeff: float = (follow_time*follow_time - time_since_spawn*time_since_spawn) / (follow_time*follow_time)
		excess_velocity = drag_coeff * player_velocity
	else:
		excess_velocity = Vector3.ZERO
		
	position += (flow_velocity + excess_velocity) * delta

func _on_kill():
	call_deferred("queue_free")

func helix_velocity(vertical_velocity: float, amplitude: float, pulsation: float) -> Vector3:
	var t: float = GameVariables.get_time_s()
	return Vector3(
		- amplitude * pulsation * sin(pulsation * t), 
		vertical_velocity,
		amplitude * pulsation * cos(pulsation * t)
	)

func _on_velocity_updated(velocity: Vector3):
	player_velocity = velocity
