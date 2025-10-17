extends Label

var current_state: Event.EVENT = Event.EVENT.START
var decay_timer: Timer
@export var decay_time: float = 10.0

var animation: AnimationPlayer

func _ready() -> void:
	# connect all event
	$/root/Zone1.event_fired.connect(_on_event_fired)
	
	# create timer for decay
	decay_timer = Timer.new()
	add_child(decay_timer)
	decay_timer.one_shot = true
	decay_timer.timeout.connect(_on_decay_timer_timeout)
	
	animation = $AnimationPlayer
	_process_state()

func _process_state() -> void:
	match current_state:
		Event.EVENT.START:
			text = "I should find some clues about the shipwreck around me."
		Event.EVENT.NO_CLUE_FOUND:
			text = "If I get closer to a debris, my metal detector will beep."
		Event.EVENT.CLUE_FOUND:
			text = "I found something, I should bring it to the bell for later analysis."
		Event.EVENT.ALL_CLUE_FOUND:
			text = "I found something, I should bring it to the bell for later analysis."
		Event.EVENT.CABLE_CUT:
			text = "I found something, I should bring it to the bell for later analysis."
		Event.EVENT.VICTORY:
			text = "I found something, I should bring it to the bell for later analysis."
		Event.EVENT.TOO_MUCH_FISH_AROUND:
			text = "Fish"
		Event.EVENT.HALF_OXYGEN:
			text = "Fish"
		Event.EVENT.ALMOST_NO_OXYGEN:
			text = "Fish"
		Event.EVENT.BELL_REFILLED_OXYGEN:
			text = "Fish"
		Event.EVENT.DYING:
			text = "Fish"
	play_animation_text_display()

func _on_decay_timer_timeout() -> void:
	animation.play("decay")
	await animation.animation_finished
	text = ""
	visible_ratio = 0

func play_animation_text_display():
	modulate.a = 255
	animation.play("text_display")
	decay_timer.start(decay_time)

func _on_event_fired(event: Event.EVENT) -> void:
	current_state = event
	_process_state()
