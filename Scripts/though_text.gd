extends Label

enum TEXT { START }
var current_state: TEXT = TEXT.START
var decay_timer: Timer
@export var decay_time: float = 10.0

func _ready() -> void:
	decay_timer = Timer.new()
	add_child(decay_timer)
	decay_timer.one_shot = true
	decay_timer.timeout.connect(_on_decay_timer_timeout)

	_process_state()

func _process_state() -> void:
	match current_state:
		TEXT.START:
			text = "I should find some clues about the shipwreck around me."

	$AnimationPlayer.play("text_display")
	decay_timer.start(decay_time)

func _on_decay_timer_timeout() -> void:
	$AnimationPlayer.play("decay")
