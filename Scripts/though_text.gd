extends Label

var current_state: Event.EVENT = Event.EVENT.START
var decay_timer: Timer
@export var decay_time: float = 10.0

var animation: AnimationPlayer

func _ready() -> void:
	# connect all event
	EventBus.event_fired.connect(_on_event_fired)
	
	# create timer for decay
	decay_timer = Timer.new()
	add_child(decay_timer)
	decay_timer.one_shot = true
	decay_timer.timeout.connect(_on_decay_timer_timeout)
	
	animation = $AnimationPlayer
	animation.animation_finished.connect(_on_animation_finished)
	_process_state()

func _process_state() -> void:
	match current_state:
		Event.EVENT.START:
			text = "I should find some clues about the shipwreck around me."
		Event.EVENT.NO_CLUE_FOUND:
			text = "If I get closer to debris, my metal detector will beep."
		Event.EVENT.CLUE_FOUND:
			text = "I found something, I should bring it to the bell for analysis later."
		Event.EVENT.ALL_CLUE_FOUND:
			text = "I think I've got everything. I should head back to the bell."
		Event.EVENT.CABLE_CUT:
			text = "What the... My cable has been cut! Finding the bell will be a nightmare !"
		Event.EVENT.VICTORY:
			text = "You found all clues about the wreck's location. Your efforts allowed its recovery."
		Event.EVENT.TOO_MUCH_FISH_AROUND:
			text = "Fish 🐟"
		Event.EVENT.HALF_OXYGEN:
			text = "I'm running low on oxygen, should return to the bell to refill."
		Event.EVENT.ALMOST_NO_OXYGEN:
			text = "Almost.... No... Air... Must... Refill... at bell..."
		Event.EVENT.BELL_REFILLED_OXYGEN:
			text = "Grabbed a fresh bottle of oxygen. Let's go back to the search."
		Event.EVENT.DYING:
			text = "You drowned before you could reach the bell."
	play_animation_text_display()

func _on_decay_timer_timeout() -> void:
	animation.play("decay")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "decay":
		text = ""
		visible_ratio = 0
		
func play_animation_text_display():
	animation.stop()
	modulate.a = 255
	animation.play("text_display")
	decay_timer.start(decay_time)

func _on_event_fired(event: Event.EVENT) -> void:
	current_state = event
	_process_state()
