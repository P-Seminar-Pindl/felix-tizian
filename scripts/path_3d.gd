extends Node3D

@onready var path: Path3D = $"."

@export_category("Curve Settings")
@export var segment_step := 0.1          # Smoothness of the rails
@export var tie_spacing_step := 0.4      # How far apart the horizontal planks are
@export var smoothing_passes := 2
@export var smoothing_samples := 1600 
@export var track_separation := 1.5 

@export_category("Colors")
@export var rail_color := Color8(200, 200, 200, 255) # Metallic silver
@export var tie_color := Color8(105, 70, 45, 255)    # Wooden brown

@export_category("Dimensions")
# X = Width, Y = Height, Z = Length along track
@export var rail_size := Vector3(0.1, 0.15, 0.2) 
# X = Long span across track, Y = Thickness, Z = Width of plank
@export var tie_size := Vector3(2.0, 0.06, 0.2) 

func _ready() -> void:
	if path == null or path.curve == null:
		return

	path.curve = _create_smoothed_curve(path.curve)
	_build_track_multimesh()

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

func _build_track_multimesh() -> void:
	# Clear out any previous MultiMesh instances
	for child in path.get_children():
		if child is MultiMeshInstance3D:
			child.queue_free()

	var length := path.curve.get_baked_length()
	
	# Temporary arrays to hold transform data before pushing to GPU
	var rail_transforms: Array[Transform3D] = []
	var tie_transforms: Array[Transform3D] = []

	# --- PASS 1: Generate Parallel Rails ---
	var d := 0.0
	var prev_pos := path.curve.sample_baked(0.0)
	
	while d < length:
		d += segment_step
		if d > length: d = length

		var pos := path.curve.sample_baked(d)
		var diff := pos - prev_pos
		if diff.length() < 0.0001: 
			prev_pos = pos
			continue

		var center_pos := (prev_pos + pos) * 0.5
		var direction := diff.normalized()
		var side_dir := direction.cross(Vector3.UP).normalized()
		var half_offset := side_dir * (track_separation * 0.5)

		var base_xform := Transform3D().looking_at(direction, Vector3.UP)

		# Left Rail Transform
		var left_xform := base_xform
		left_xform.origin = center_pos + half_offset
		rail_transforms.append(left_xform)

		# Right Rail Transform
		var right_xform := base_xform
		right_xform.origin = center_pos - half_offset
		rail_transforms.append(right_xform)

		prev_pos = pos

	# --- PASS 2: Generate Horizontal Planks (Ties) ---
	d = 0.0
	prev_pos = path.curve.sample_baked(0.0)
	
	while d < length:
		d += tie_spacing_step
		if d > length: d = length

		var pos := path.curve.sample_baked(d)
		var diff := pos - prev_pos
		if diff.length() < 0.0001:
			prev_pos = pos
			continue

		var center_pos := (prev_pos + pos) * 0.5
		var direction := diff.normalized()

		# Planks align centered on the track, spanning outward on the X axis
		var tie_xform := Transform3D().looking_at(direction, Vector3.UP)
		tie_xform.origin = center_pos
		tie_transforms.append(tie_xform)

		prev_pos = pos

	# --- PASS 3: Instantiate MultiMeshes ---
	if rail_transforms.size() > 0:
		_create_multimesh_instance("Track_Rails", rail_size, rail_color, rail_transforms)
	if tie_transforms.size() > 0:
		_create_multimesh_instance("Track_Planks", tie_size, tie_color, tie_transforms)

func _create_multimesh_instance(node_name: String, box_size: Vector3, color: Color, transforms: Array[Transform3D]) -> void:
	var multimesh_instance := MultiMeshInstance3D.new()
	multimesh_instance.name = node_name
	
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	
	# Build the shared mesh resource
	var box_mesh := BoxMesh.new()
	box_mesh.size = box_size
	
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	box_mesh.material = material
	multimesh.mesh = box_mesh
	
	# Allocate memory on the GPU all at once
	multimesh.instance_count = transforms.size()
	for i in range(transforms.size()):
		multimesh.set_instance_transform(i, transforms[i])
		
	multimesh_instance.multimesh = multimesh
	path.add_child(multimesh_instance)
