extends Node

@onready var bubble_template: PackedScene = load("res://Scenes/Bubble.tscn")
@onready var oxygen_controller: Node = $".."
@onready var player_controller: CharacterBody3D = $"../.."

@export var spawn_distance_forward: float = 0.2
@export var spawn_offset_left: Vector2 = Vector2(0.05, 0.15)
@export var spawn_offset_down: Vector2 = Vector2(0.1, 0.4)

func _ready() -> void:
	oxygen_controller.depletion_event.connect(_on_depletion_event)

func _on_depletion_event(n_bubbles: int) -> void:
	var vision_basis = player_controller._get_vision_basis()
	var vision_position = player_controller._get_vision_position()

	for i in range(n_bubbles):
		var bubble = bubble_template.instantiate()
		add_child(bubble)

		var distance_x = randf_range(spawn_offset_left.x, spawn_offset_left.y)
		var distance_y = randf_range(spawn_offset_down.x, spawn_offset_down.y)
		var distance_z = spawn_distance_forward

		bubble.position = vision_position \
			- vision_basis.z * distance_z\
			- vision_basis.x * distance_x\
			- vision_basis.y * distance_y
		bubble.player_velocity = player_controller.velocity
		player_controller.velocity_updated.connect(bubble._on_velocity_updated)
