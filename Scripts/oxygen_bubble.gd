extends CSGSphere3D

var speed: float = 1.0
var fading_speed: float = 0.01
var pulsation: float = 10.0
var shaking_size: float = 0.03
var killer: Timer
var flag_alpha: bool = false

func _ready() -> void:
	killer = $Killer
	killer.start(10.0)
	killer.timeout.connect(_on_kill)

func _process(delta: float) -> void:
	position += helix_pattern_diff(0.5, 0.1, speed) * delta

func _on_kill():
	call_deferred("queue_free")

func helix_pattern_diff(a: float, b: float, helix_speed: float) -> Vector3:
	var t_ms: int = GameVariables.get_time_ms()
	var t: float = t_ms / 1000.0
	return Vector3(- a * sin(helix_speed * t), b, a * cos(helix_speed * t)) * helix_speed
