extends Node3D

class_name game_controller

signal game_ended

var collectible_picked: int = 0
var collectibles_size: int
var no_clue_timer: Timer
var game_ended_timer: Timer

@export var no_clue_event_delay: float = 60.0
@export var game_ended_delay: float = 5.0

@onready var player: CharacterBody3D = $SubViewportContainer/SubViewport/PlayerController
@onready var bell: Node3D = $SubViewportContainer/SubViewport/Bell

func _ready() -> void:
	# collectibles
	var collectibles: Array[Node] = get_tree().get_nodes_in_group("Collectibles")
	collectibles_size = collectibles.size()

	for collectible in collectibles:
		if collectible is CollectibleDetector:
			collectible.collectible_picked_up.connect(_on_collectible_picked_up)

	# handles no clue event
	no_clue_timer = Timer.new()
	add_child(no_clue_timer)
	no_clue_timer.one_shot = true
	no_clue_timer.timeout.connect(_on_no_clue_timer_timeout)
	no_clue_timer.start(no_clue_event_delay)
	
	# handles oxygen events
	EventBus.player_half_oxygen.connect(_on_player_half_oxygen)
	EventBus.player_almost_no_oxygen.connect(_on_player_almost_no_oxygen)
	EventBus.player_out_of_oxygen.connect(_on_player_out_of_oxygen)
	
	# handles bell events
	bell.get_node("OxygenRefillArea").body_entered.connect(_on_bell_body_entered)
	bell.get_node("OxygenRefillArea").body_exited.connect(_on_bell_body_exited)

	# handles end of game
	game_ended_timer = Timer.new()
	add_child(game_ended_timer)
	game_ended_timer.one_shot = true
	game_ended_timer.timeout.connect(_on_game_ended_timer_timeout)
	game_ended.connect(_on_game_ended)

func _on_no_clue_timer_timeout() -> void:
	EventBus.event_fired.emit(Event.EVENT.NO_CLUE_FOUND)

func _on_collectible_picked_up() -> void:
	collectible_picked += 1
	no_clue_timer.stop()
	if collectible_picked >= collectibles_size:
		EventBus.event_fired.emit(Event.EVENT.ALL_CLUE_FOUND)
	else:
		EventBus.event_fired.emit(Event.EVENT.CLUE_FOUND)

func _on_game_ended() -> void:
	Transition.transition()
	await Transition.on_transition_finished
	## TODO: add the correct scene
	get_tree().change_scene_to_file("res://Scenes/NyluxTesting.tscn")

func _on_player_half_oxygen() -> void:
	EventBus.event_fired.emit(Event.EVENT.HALF_OXYGEN)

func _on_player_almost_no_oxygen() -> void:
	EventBus.event_fired.emit(Event.EVENT.ALMOST_NO_OXYGEN)

func _on_player_out_of_oxygen() -> void:
	EventBus.event_fired.emit(Event.EVENT.DYING)
	game_ended_timer.start(game_ended_delay)

func _on_game_ended_timer_timeout() -> void:
	game_ended.emit()

func _on_bell_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if collectible_picked >= collectibles_size:
			EventBus.event_fired.emit(Event.EVENT.VICTORY)
			game_ended_timer.start(game_ended_delay)
		else:
			EventBus.event_fired.emit(Event.EVENT.BELL_REFILLED_OXYGEN)
			EventBus.infinite_oxygen_started.emit()

func _on_bell_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		EventBus.infinite_oxygen_ended.emit()
