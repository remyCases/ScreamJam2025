extends Node3D

class_name CollectibleDetector

signal collectible_picked_up

@export var collectible_time: float = 2.0
@export var outer_radius: float
@export var middle_radius: float
@export var inner_radius: float

@onready var outer_detector: Area3D = Area3D.new()
@onready var middle_detector: Area3D = Area3D.new()
@onready var inner_detector: Area3D = Area3D.new()

var collectible_timer: Timer

func _ready() -> void:
	collectible_timer = Timer.new()
	collectible_timer.timeout.connect(_on_collectible_timer_timeout)
	collectible_timer.one_shot = true
	add_child(collectible_timer)

	create_cylinder_area(outer_detector, outer_radius)
	create_cylinder_area(middle_detector, middle_radius)
	create_cylinder_area(inner_detector, inner_radius)
	add_to_group("Collectibles")

	inner_detector.body_exited.connect(_on_inner_body_exited)
	inner_detector.body_entered.connect(_on_inner_body_entered)

func create_cylinder_area(area: Area3D, radius: float):
	add_child(area)
	var shape = CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = radius
	shape.shape.height = 10.0
	area.add_child(shape)

	# collision layer as collectibles
	area.collision_layer = 0b00000000_00000000_00000000_00000010
	# collide only with player
	area.collision_mask = 0b00000000_00000000_00000000_00000001

func _on_inner_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		collectible_timer.stop()

func _on_inner_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		collectible_timer.start(collectible_time)

func _on_collectible_timer_timeout() -> void:
	collectible_picked_up.emit()
	call_deferred("queue_free")
