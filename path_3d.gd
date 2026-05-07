extends Node3D
@onready var path: Path3D = $"."
func _ready() -> void:
	if path == null:
		return
	var schiene = load("res://schiene.obj")
	var length := path.curve.get_baked_length()
	var step := 0.5
	var d := 0.0
	var prev_pos: Vector3
	var first := true
	while d <= length:
		var pos := path.curve.sample_baked(d)
		if not first:
			var mid := (prev_pos + pos) / 2.0
			var diff := pos - prev_pos
			var dist := diff.length()
			var rail := MeshInstance3D.new()
			rail.mesh = schiene
			rail.position = mid
			rail.scale = Vector3(dist, 1.0, 1.0)
			rail.rotation = Vector3i($"Path3D/PathFollow3D/Train".rotation_degrees()) #global_transform.basis.get_euler() * (180.0 / PI) * Vector3(1, 1, 0)
			path.add_child(rail)
		prev_pos = pos
		first = false
		d += step
