extends Node3D

class_name CollectibleDetector

@export var outer_radius: float
@export var middle_radius: float
@export var inner_radius: float

@onready var outer_detector: Area3D = Area3D.new()
@onready var middle_detector: Area3D = Area3D.new()
@onready var inner_detector: Area3D = Area3D.new()

func _ready() -> void:
	create_cylinder_area(outer_detector, outer_radius)
	create_cylinder_area(middle_detector, middle_radius)
	create_cylinder_area(inner_detector, inner_radius)
	add_to_group("Collectibles")

func create_cylinder_area(area: Area3D, radius: float):
	add_child(area)
	var shape = CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = radius
	shape.shape.height = 4.0
	area.add_child(shape)

	# collision layer as collectibles
	area.collision_layer = 0b00000000_00000000_00000000_00000010
	# collide only with player
	area.collision_mask = 0b00000000_00000000_00000000_00000001
