extends Node3D

class_name game_controller

signal game_ended

var collectible_picked: int = 0
var collectibles_size: int
var no_clue_timer: Timer
var game_ended_timer: Timer

@export var no_clue_event_delay: float = 60.0
@export var game_ended_delay: float = 5.0

var player: CharacterBody3D
@onready var bell: Node3D = $SubViewportContainer/SubViewport/Bell
@onready var menu_camera: Camera3D = $SubViewportContainer/SubViewport/CameraMenu
@onready var main_menu: VBoxContainer = $MainMenu
@onready var terrain: Terrain3D = $SubViewportContainer/SubViewport/Terrain3D
var cable: Node3D

func _ready() -> void:
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
	
	# handles oxygen events
	EventBus.player_half_oxygen.connect(_on_player_half_oxygen)
	EventBus.player_almost_no_oxygen.connect(_on_player_almost_no_oxygen)
	EventBus.player_out_of_oxygen.connect(_on_player_out_of_oxygen)
	
	# handles bell events
	bell.get_node("OxygenRefillArea").body_entered.connect(_on_bell_body_entered)
	bell.get_node("OxygenRefillArea").body_exited.connect(_on_bell_body_exited)
	bell.get_node("CableCutArea").body_exited.connect(_on_cable_body_exited)

	# handles end of game
	game_ended_timer = Timer.new()
	add_child(game_ended_timer)
	game_ended_timer.one_shot = true
	game_ended_timer.timeout.connect(_on_game_ended_timer_timeout)
	game_ended.connect(_on_game_ended)
	
	terrain.set_camera(menu_camera)
	main_menu.get_node("MarginStart/Start").pressed.connect(_on_game_start)
	main_menu.get_node("MarginQuit/Quit").pressed.connect(func(): get_tree().quit())

func _on_game_start() -> void:
	menu_camera.current = false
	main_menu.visible = false

	player = load("res://Scenes/PlayerController.tscn").instantiate()
	player.position = Vector3(133.818, 8.948, -119.89)
	player.rotation_degrees = Vector3(0.0, 156.5, 0.0)

	player.vertical_look_limit = 40.0
	player.maximal_distance_anchor = 80.0
	player.anchor = bell

	get_node("SubViewportContainer/SubViewport").add_child(player)
	
	cable = load("res://Scenes/PseudoPhysicsCable.tscn").instantiate()
	cable.start_point = $SubViewportContainer/SubViewport/Bell/RopeSpawnPoint
	cable.end_point = player
	cable.number_of_segments = 20
	cable.cable_thickness = 0.02
	cable.cable_mesh = load("res://Scenes/CableSegment.tscn")

	get_node("SubViewportContainer/SubViewport").add_child(cable)
	
	var player_camera: Camera3D = player.get_node("CameraPivot/Camera3D")
	terrain.set_camera(player_camera)
	player_camera.current = true
	no_clue_timer.start(no_clue_event_delay)
	menu_camera.queue_free()
	
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
	get_tree().reload_current_scene()

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

func _on_cable_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and cable:
		call_deferred("_cut_cable")
		EventBus.event_fired.emit(Event.EVENT.CABLE_CUT)

func _cut_cable() -> void:
	cable.queue_free()
