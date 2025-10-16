extends Label

enum TEXT 
{ 
	START, 
	NO_CLUE_FOUND,
	CLUE_FOUND,
	ALL_CLUE_FOUND,
	CABLE_CUT,
	VICTORY,
	TOO_MUCH_FISH_AROUND,
	HALF_OXYGEN,
	ALMOST_NO_OXYGEN,
	BELL_REFILLED_OXYGEN,
	DYING,
}

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
		TEXT.NO_CLUE_FOUND:
			text = "If I get closer to a debris, my metal detector will beep."
		TEXT.CLUE_FOUND:
			text = "I found something, I should bring it to the bell for later analysis."
		TEXT.ALL_CLUE_FOUND:
			text = "I found something, I should bring it to the bell for later analysis."
		TEXT.CABLE_CUT:
			text = "I found something, I should bring it to the bell for later analysis."
		TEXT.VICTORY:
			text = "I found something, I should bring it to the bell for later analysis."
		TEXT.TOO_MUCH_FISH_AROUND:
			text = "Fish"
		TEXT.HALF_OXYGEN:
			text = "Fish"
		TEXT.ALMOST_NO_OXYGEN:
			text = "Fish"
		TEXT.BELL_REFILLED_OXYGEN:
			text = "Fish"
		TEXT.DYING:
			text = "Fish"

	$AnimationPlayer.play("text_display")
	decay_timer.start(decay_time)

func _on_decay_timer_timeout() -> void:
	$AnimationPlayer.play("decay")
