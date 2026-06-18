extends Node3D

@onready var path: Path3D = $"."

@export var segment_step := 0.05 
@export var smoothing_passes := 2
@export var smoothing_samples := 1600 
@export var track_separation := 1.5 

# Color of the lines in the viewport
@export var track_color := Color8(255, 255, 255, 255) 

func _ready() -> void:
	if path == null or path.curve == null:
		return

	path.curve = _create_smoothed_curve(path.curve)
	_build_parallel_lines()

func _create_smoothed_curve(source: Curve3D) -> Curve3D:
	var length := source.get_baked_length()
	var points := PackedVector3Array()

	for i in range(smoothing_samples + 1):
		var t := length * float(i) / smoothing_samples
		points.append(source.sample_baked(t))

	for _i in range(smoothing_passes):
		var smoothed := PackedVector3Array()
		var size := points.size()
		for index in range(size):
			var sum := points[index]
			var count := 1
			
			if index > 0:
				sum += points[index - 1]
				count += 1
			elif source.closed:
				sum += points[size - 2]
				count += 1
				
			if index < size - 1:
				sum += points[index + 1]
				count += 1
			elif source.closed:
				sum += points[1]
				count += 1
				
			smoothed.append(sum / count)
		points = smoothed

	if source.closed and points.size() > 1:
		points[points.size() - 1] = points[0]

	var smoothed_curve := Curve3D.new()
	smoothed_curve.closed = source.closed
	for point in points:
		smoothed_curve.add_point(point)
	return smoothed_curve

func _build_parallel_lines() -> void:
	# Clear out any old instances
	for child in path.get_children():
		if child is MeshInstance3D:
			child.queue_free()

	var length := path.curve.get_baked_length()
	var d := 0.0
	var prev_pos := path.curve.sample_baked(0.0)

	# Arrays to hold our raw vertex coordinates
	var left_line_points := PackedVector3Array()
	var right_line_points := PackedVector3Array()

	# First pass: Collect all the offset vertex points mathematically
	while d < length:
		d += segment_step
		if d > length:
			d = length

		var pos := path.curve.sample_baked(d)
		var diff := pos - prev_pos
		var dist := diff.length()
		
		if dist < 0.0001: 
			prev_pos = pos
			continue

		var center_pos := (prev_pos + pos) * 0.5
		var direction := diff.normalized()
		var side_dir := direction.cross(Vector3.UP).normalized()
		var half_offset := side_dir * (track_separation * 0.5)

		# Store the raw positions directly without creating objects
		left_line_points.append(center_pos + half_offset)
		right_line_points.append(center_pos - half_offset)

		prev_pos = pos

	# Second pass: Generate the meshes from raw points (No rotations required!)
	_create_line_mesh(left_line_points)
	_create_line_mesh(right_line_points)

func _create_line_mesh(points: PackedVector3Array) -> void:
	if points.size() < 2:
		return

	var mesh_instance := MeshInstance3D.new()
	var immediate_mesh := ImmediateMesh.new()
	var material := ORMMaterial3D.new()
	
	# Configure a basic unshaded color material for the path lines
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = track_color

	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, material)
	for point in points:
		immediate_mesh.surface_add_vertex(point)
	immediate_mesh.surface_end()

	mesh_instance.mesh = immediate_mesh
	path.add_child(mesh_instance)
