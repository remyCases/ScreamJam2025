extends Node

signal half_oxygen
signal almost_no_oxygen
signal out_of_oxygen

var max_oxygen: int = 100
var current_oxygen: int = max_oxygen
var max_oxygen_level: int = 5

@export var rate_oxygen_natural_depletion: int = 1
var rate_oxygen_sanity_depletion: int
var rate_oxygen_depletion: int

@onready var sanity_controller: Node = $"../SanityController"
@onready var breathing_controller: Node = $"../BreathingController"
@onready var breath_in_sound: AudioStreamPlayer = $"BreathInSound"
@onready var breath_out_sound: AudioStreamPlayer = $"BreathOutSound"

var half_oxygen_sent: bool = false
var almost_no_oxygen_sent: bool = false

func _ready() -> void:
	breathing_controller.exhaled.connect(_on_exhaled)
	breathing_controller.inhaled.connect(_on_inhaled)

func _on_exhaled() -> void:
	rate_oxygen_sanity_depletion = sanity_controller.get_oxygen_depletion_by_sanity()
	rate_oxygen_depletion = rate_oxygen_natural_depletion + rate_oxygen_sanity_depletion

	current_oxygen -= rate_oxygen_depletion
	breath_out_sound.play()
	if current_oxygen < 0:
		out_of_oxygen.emit()
		breathing_controller._stop_breathing()
	elif current_oxygen < max_oxygen / 10.0 and !almost_no_oxygen_sent:
		almost_no_oxygen.emit()
		almost_no_oxygen_sent = true
	elif current_oxygen < max_oxygen / 2.0 and !half_oxygen_sent:
		half_oxygen.emit()
		half_oxygen_sent = true

func _on_inhaled() -> void:
	breath_in_sound.play()

func get_oxygen_level() -> int:
	return min(max_oxygen_level, current_oxygen / 20.0)
