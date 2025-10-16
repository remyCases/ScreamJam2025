extends Node3D

class_name game_controller

signal game_won
signal game_lost

var collectible_picked: int = 0
var collectibles_size: int

@onready var player: CharacterBody3D = $SubViewportContainer/SubViewport/PlayerController
var game_lost_timer: Timer

@export var game_lost_delay: float = 5.0

func _ready() -> void:
	# collectibles
	var collectibles: Array[Node] = get_tree().get_nodes_in_group("Collectibles")
	collectibles_size = collectibles.size()

	for collectible in collectibles:
		if collectible is CollectibleDetector:
			collectible.collectible_picked_up.connect(_on_collectible_picked_up)

	# handles end of game
	player.player_out_of_oxygen.connect(_on_player_out_of_oxygen)
	game_lost_timer = Timer.new()
	add_child(game_lost_timer)
	game_lost_timer.one_shot = true
	game_lost_timer.timeout.connect(_on_game_lost_timer_timeout)
	game_lost.connect(_on_game_lost)
	game_won.connect(_on_game_won)

func _on_collectible_picked_up() -> void:
	collectible_picked += 1
	if collectible_picked >= collectibles_size:
		game_won.emit()

func _on_game_lost() -> void:
	Transition.transition()
	await Transition.on_transition_finished
	## TODO: add the correct scene
	get_tree().change_scene_to_file("res://Scenes/NyluxTesting.tscn")

func _on_game_won() -> void:
	Transition.transition()
	await Transition.on_transition_finished
	## TODO: add the correct scene
	get_tree().change_scene_to_file("res://Scenes/NyluxTesting.tscn")

func _on_player_out_of_oxygen() -> void:
	game_lost_timer.start(game_lost_delay)

func _on_game_lost_timer_timeout() -> void:
	game_lost.emit()
