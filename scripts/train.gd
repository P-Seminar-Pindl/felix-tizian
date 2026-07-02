extends CharacterBody3D

@export var path_follow: PathFollow3D
@export var max_speed := 95
@export var braking := 6.0
@export var acceleration := 2
@export var progress_scale := 0.5

var current_speed := 0.0

func _ready() -> void:
	if path_follow == null:
		path_follow = get_parent() as PathFollow3D

func _physics_process(delta: float) -> void:
	if path_follow == null:
		return
		
	var tacho := $"./Führerstand/speed"
	var stext = round(current_speed*-1.67)
	get_node(tacho.get_path()).text = str("Speed: "+str(stext))

	var input_dir := 0.0
	if Input.is_key_pressed(KEY_DOWN):
		input_dir += 1.0
	if Input.is_key_pressed(KEY_UP):
		input_dir -= 1.0
	if Input.is_key_pressed(KEY_SPACE):
		input_dir = 0.0

	if input_dir != 0.0:
		current_speed = move_toward(current_speed, input_dir * max_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, braking * delta)

	path_follow.progress += current_speed * progress_scale * delta
	path_follow.progress = clamp(path_follow.progress, 0.0, path_follow.get_parent().curve.get_baked_length())
