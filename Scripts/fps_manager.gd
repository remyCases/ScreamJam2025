extends Label

func _process(_delta: float) -> void:
	get_input()
	text = "FPS: %s" % Engine.get_frames_per_second()

func get_input() -> void:
	if Input.is_action_just_pressed("DisplayFPS"):
		visible = not visible
