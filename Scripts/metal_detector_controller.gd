extends Node

@onready var metal_sound: AudioStreamPlayer = $MetalDetectorSound

@export var pitch_far: float
@export var pitch_middle: float
@export var pitch_close: float

func _ready() -> void:
	var collectibles: Array[Node] = get_tree().get_nodes_in_group("Collectibles")

	for collectible in collectibles:
		if collectible is CollectibleDetector:
			collectible.outer_detector.body_exited.connect(_transition_off)
			collectible.outer_detector.body_entered.connect(_transition_far)
			collectible.middle_detector.body_exited.connect(_transition_far)
			collectible.middle_detector.body_entered.connect(_transition_middle)
			collectible.inner_detector.body_exited.connect(_transition_middle)
			collectible.inner_detector.body_entered.connect(_transition_close)

func _transition_off(body: Node3D) -> void:
	if body is CharacterBody3D:
		metal_sound.stop()

func _transition_far(body: Node3D) -> void:
	if body is CharacterBody3D:
		metal_sound.pitch_scale = pitch_far
		metal_sound.play()

func _transition_middle(body: Node3D) -> void:
	if body is CharacterBody3D:
		metal_sound.pitch_scale = pitch_middle

func _transition_close(body: Node3D) -> void:
	if body is CharacterBody3D:
		metal_sound.pitch_scale = pitch_close
