extends Node

var time_engine_start: int

func _ready() -> void:
	time_engine_start = Time.get_ticks_msec()

func get_time_ms() -> int:
	return Time.get_ticks_msec() - time_engine_start
