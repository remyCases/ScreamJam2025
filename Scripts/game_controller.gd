extends Node3D

class_name game_controller

signal game_ended
signal event_fired

var collectible_picked: int = 0
var collectibles_size: int

@onready var player: CharacterBody3D = $SubViewportContainer/SubViewport/PlayerController
var game_ended_timer: Timer

@export var game_ended_delay: float = 5.0

func _ready() -> void:
	# collectibles
	var collectibles: Array[Node] = get_tree().get_nodes_in_group("Collectibles")
	collectibles_size = collectibles.size()

	for collectible in collectibles:
		if collectible is CollectibleDetector:
			collectible.collectible_picked_up.connect(_on_collectible_picked_up)

	# handles end of game
	player.player_half_oxygen.connect(_on_player_half_oxygen)
	player.player_almost_no_oxygen.connect(_on_player_almost_no_oxygen)
	player.player_out_of_oxygen.connect(_on_player_out_of_oxygen)
	game_ended_timer = Timer.new()
	add_child(game_ended_timer)
	game_ended_timer.one_shot = true
	game_ended_timer.timeout.connect(_on_game_ended_timer_timeout)
	game_ended.connect(_on_game_ended)

func _on_collectible_picked_up() -> void:
	collectible_picked += 1
	if collectible_picked >= collectibles_size:
		event_fired.emit(Event.EVENT.ALL_CLUE_FOUND)
	else:
		event_fired.emit(Event.EVENT.CLUE_FOUND)

func _on_close_to_bell() -> void:
	if collectible_picked >= collectibles_size:
		event_fired.emit(Event.EVENT.VICTORY)
		game_ended_timer.start(game_ended_delay)

func _on_game_ended() -> void:
	Transition.transition()
	await Transition.on_transition_finished
	## TODO: add the correct scene
	get_tree().change_scene_to_file("res://Scenes/NyluxTesting.tscn")

func _on_player_half_oxygen() -> void:
	event_fired.emit(Event.EVENT.HALF_OXYGEN)

func _on_player_almost_no_oxygen() -> void:
	event_fired.emit(Event.EVENT.ALMOST_NO_OXYGEN)

func _on_player_out_of_oxygen() -> void:
	event_fired.emit(Event.EVENT.DYING)
	game_ended_timer.start(game_ended_delay)

func _on_game_ended_timer_timeout() -> void:
	game_ended.emit()
