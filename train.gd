extends CharacterBody3D

var gas: float = 0
@export var speed := 1
@onready var Path = $".."
func _physics_process(delta):

	# Direkt Tasten abfragen ohne Input Map
	if Input.is_key_pressed(KEY_UP):
		gas += 0.004
	if Input.is_key_pressed(KEY_DOWN):
		gas -= 0.005
	if Input.is_key_pressed(KEY_SPACE):
		gas = 0
	Path.progress -= gas * 0.01
	# Bewegung nach vorne (lokaler Z-Achse)
	#velocity = transform.basis.z * gas * speed
	#move_and_slide()
