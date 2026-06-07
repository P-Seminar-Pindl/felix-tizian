extends Node3D

@onready var path: Path3D = $"."
@export var rail_mesh: Mesh = preload("res://assets/models/schiene.obj")
@export var segment_step := 0.5
@export var smoothing_passes := 2
@export var smoothing_samples := 160

func _ready() -> void:
	if path == null or path.curve == null:
		return

	path.curve = _create_smoothed_curve(path.curve)
	_build_rails()

func _create_smoothed_curve(source: Curve3D) -> Curve3D:
	var length := source.get_baked_length()
	var points := PackedVector3Array()

	for i in range(smoothing_samples + 1):
		var t := length * float(i) / smoothing_samples
		points.append(source.sample_baked(t))

	for _i in range(smoothing_passes):
		var smoothed := PackedVector3Array()
		for index in range(points.size()):
			var sum := points[index]
			var count := 1
			if index > 0:
				sum += points[index - 1]
				count += 1
			if index < points.size() - 1:
				sum += points[index + 1]
				count += 1
			smoothed.append(sum / count)
		points = smoothed

	if source.closed and points.size() > 1:
		points.append(points[0])

	var smoothed_curve := Curve3D.new()
	for point in points:
		smoothed_curve.add_point(point)
	return smoothed_curve

func _build_rails() -> void:
	for child in path.get_children():
		if child is MeshInstance3D:
			child.queue_free()

	var length := path.curve.get_baked_length()
	var d := 0.0
	var prev_pos := path.curve.sample_baked(0.0)

	while d < length:
		d += segment_step
		if d > length:
			d = length

		var pos := path.curve.sample_baked(d)
		var diff := pos - prev_pos
		var dist := diff.length()
		if dist < 0.001:
			prev_pos = pos
			continue

		var rail := MeshInstance3D.new()
		rail.mesh = rail_mesh
		rail.position = (prev_pos + pos) * 0.5
		rail.scale = Vector3(1.0, 1.0, dist)
		rail.transform = rail.transform.looking_at(pos, Vector3.UP)
		rail.transform.origin = rail.position
		path.add_child(rail)

		prev_pos = pos
