extends Node

class_name state_machine_breathing

enum BREATHING {OFF, EXHALING, INHALING}
signal exhaled
signal inhaled
signal breathing_started
signal breathing_stopped

@export var time_after_exhaling: float
@export var time_after_inhaling: float

var current_state: BREATHING = BREATHING.OFF
var _timer: Timer

func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

func _start_breathing() -> void:
	if current_state != BREATHING.OFF:
		return
		
	breathing_started.emit()
	_transition_on_inhaling()
	
func _stop_breathing() -> void:
	if current_state == BREATHING.OFF:
		return
	
	_timer.stop()
	current_state = BREATHING.OFF
	breathing_stopped.emit()

func _transition_on_exhaling() -> void:
	current_state = BREATHING.EXHALING
	exhaled.emit()
	_timer.start(time_after_exhaling)

func _transition_on_inhaling() -> void:
	current_state = BREATHING.INHALING
	inhaled.emit()
	_timer.start(time_after_inhaling)

func _on_timer_timeout() -> void:
	match current_state:
		BREATHING.EXHALING:
			_transition_on_inhaling()
		BREATHING.INHALING:
			_transition_on_exhaling()
		BREATHING.OFF:
			pass

func _exit_tree() -> void:
	if _timer:
		_timer.queue_free()
