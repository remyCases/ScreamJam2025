extends Node

var nb_low: int = 0
var nb_mid: int = 0
var nb_high: int = 0

@onready var metal_sound: AudioStreamPlayer = $MetalDetectorSound

@export var pitch_far: float
@export var pitch_middle: float
@export var pitch_close: float

func _ready() -> void:
	var collectibles: Array[Node] = get_tree().get_nodes_in_group("Collectibles")

	for collectible in collectibles:
		if collectible is CollectibleDetector:
			collectible.outer_detector.body_exited.connect(_transition_off)
			collectible.outer_detector.body_entered.connect(_transition_off_to_far)
			collectible.middle_detector.body_exited.connect(_transition_mid_to_far)
			collectible.middle_detector.body_entered.connect(_transition_far_to_mid)
			collectible.inner_detector.body_exited.connect(_transition_high_to_mid)
			collectible.inner_detector.body_entered.connect(_transition_mid_to_high)

func _transition_off(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_low -= 1
		if nb_low == 0:
			metal_sound.stop()

func _transition_off_to_far(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_low += 1
		if nb_mid == 0 and nb_high == 0:
			metal_sound.pitch_scale = pitch_far
			metal_sound.play()

func _transition_mid_to_far(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_mid -= 1
		if nb_mid == 0:
			metal_sound.pitch_scale = pitch_far
			metal_sound.play()

func _transition_far_to_mid(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_mid += 1
		if nb_high == 0:
			metal_sound.pitch_scale = pitch_middle

func _transition_high_to_mid(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_high -= 1
		if nb_high == 0:
			metal_sound.pitch_scale = pitch_middle

func _transition_mid_to_high(body: Node3D) -> void:
	if body is CharacterBody3D:
		nb_high += 1
		metal_sound.pitch_scale = pitch_close
