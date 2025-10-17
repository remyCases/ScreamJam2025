extends Node

var max_sanity: int = 100
var current_sanity: int = max_sanity
var max_sanity_level = 4
var sanity_level: int

func get_sanity_level() -> int:
	return min(max_sanity_level, current_sanity / 20.0)

func get_oxygen_depletion_by_sanity() -> int:
	return min(max_sanity_level, (max_sanity - current_sanity) / 20.0)
