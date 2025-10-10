extends MeshInstance3D

@export var bubble_lifetime: float = 6.0
@export var free_rising_velocity: float = 0.29
@export var helix_frequency: float = 7.0
@export var helix_amplitude: float = 0.004

var helix_pulsation: float

@onready var killer_timer = $KillerTimer

func _ready() -> void:
	killer_timer.start(bubble_lifetime)
	killer_timer.timeout.connect(_on_kill)
	mesh.radius = 0.015
	mesh.height = 0.03
	
	helix_pulsation = helix_frequency / 2.0 * PI

func _process(delta: float) -> void:
	position += helix_velocity(
		free_rising_velocity,
		helix_amplitude,
		helix_pulsation,
	) * delta

func _on_kill():
	call_deferred("queue_free")

func helix_velocity(vertical_velocity: float, amplitude: float, pulsation: float) -> Vector3:
	var t: float = GameVariables.get_time_s()
	return Vector3(
		- amplitude * pulsation * sin(pulsation * t), 
		vertical_velocity,
		amplitude * pulsation * cos(pulsation * t)
	)
