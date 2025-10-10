extends Node

signal out_of_oxygen
signal depletion_event

var max_oxygen: int = 100
var current_oxygen: int = max_oxygen
var max_oxygen_level: int = 5

@export var rate_oxygen_natural_depletion: int = 1
var rate_oxygen_sanity_depletion: int
var rate_oxygen_depletion: int
@export var oxygen_depletion_interval_event: float = 2.0

@onready var oxygen_depletion_event_timer: Timer = $OxygenDepletionEventTimer
@onready var sanity_controller: Node = $"../SanityController"

func _ready() -> void:
	oxygen_depletion_event_timer.start(oxygen_depletion_interval_event)
	oxygen_depletion_event_timer.timeout.connect(_depletion_event)
	out_of_oxygen.connect(func(): print("you died"))

func _depletion_event() -> void:
	rate_oxygen_sanity_depletion = sanity_controller.get_oxygen_depletion_by_sanity()
	rate_oxygen_depletion = rate_oxygen_natural_depletion + rate_oxygen_sanity_depletion

	current_oxygen -= rate_oxygen_depletion
	if current_oxygen < 0:
		out_of_oxygen.emit()
		oxygen_depletion_event_timer.stop()
	else:
		depletion_event.emit(get_oxygen_level())

func get_oxygen_level() -> int:
	return min(max_oxygen_level, current_oxygen / 20)
