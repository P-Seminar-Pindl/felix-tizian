extends Node3D

@export var path: NodePath = NodePath()
@export var count := 1600
@export var path_band := 22.0
@export var min_distance := 2.5  # Minimum distance from path center
@export var tree_spacing := 2.0  # Minimum distance BETWEEN trees to avoid intersection

func _ready() -> void:
	# 1. Try to resolve the manually exported path first
	var resolved_path := get_node_or_null(path) as Path3D
	
	# 2. If not explicitly set, search dynamically up the scene tree
	if resolved_path == null:
		resolved_path = _find_path_upwards(self)

	# If still not found, safely abort
	if resolved_path == null or resolved_path.curve == null:
		push_warning("TreeGenerator: Could not find a valid Path3D node up the hierarchy.")
		return

	var curve: Curve3D = resolved_path.curve
	var baked_length := curve.get_baked_length()
	if baked_length <= 0.0:
		return

	# Get track separation from path script if it exists
	var path_script = resolved_path.get_script()
	var track_separation := 1.5
	if path_script != null:
		var track_sep_value = resolved_path.get("track_separation")
		if track_sep_value != null:
			track_separation = track_sep_value

	var safe_min_distance: float = max(min_distance, (track_separation * 0.5) + 1.5)

	# Dynamically look for Terrain3D in the parent hierarchy as well
	var terrain := _find_terrain_upwards(self)

	var trunk_material := StandardMaterial3D.new()
	trunk_material.albedo_color = Color("5a2a00")
	trunk_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	var canopy_material := StandardMaterial3D.new()
	canopy_material.albedo_color = Color("2d6a2d")
	canopy_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	randomize()

	var placed_tree_positions: Array[Vector2] = []
	var max_attempts_per_tree := 15

	for i in range(count):
		var placed_successfully := false
		var final_world_point := Vector3.ZERO
		
		for attempt in range(max_attempts_per_tree):
			var along := randf_range(0.0, baked_length)
			var local_point := curve.sample_baked(along, true)

			var angle := randf_range(0.0, TAU)
			var distance := randf_range(safe_min_distance, path_band)
			var local_offset := Vector3(cos(angle) * distance, 0.0, sin(angle) * distance)
			
			# Transform to global space correctly using the dynamically found path
			var world_point := resolved_path.to_global(local_point + local_offset)
			var new_tree_pos_2d := Vector2(world_point.x, world_point.z)
			
			var too_close := false
			for existing_pos in placed_tree_positions:
				if new_tree_pos_2d.distance_to(existing_pos) < tree_spacing:
					too_close = true
					break
			
			if not too_close:
				final_world_point = world_point
				placed_tree_positions.append(new_tree_pos_2d)
				placed_successfully = true
				break
		
		if not placed_successfully:
			continue

		var ground_height := final_world_point.y
		if terrain != null and terrain.data != null:
			ground_height = terrain.data.get_height(final_world_point)
			if is_nan(ground_height):
				ground_height = final_world_point.y

		var tree := Node3D.new()
		tree.position = Vector3(final_world_point.x, ground_height, final_world_point.z)
		tree.rotation.y = randf_range(0.0, TAU)
		tree.scale = Vector3.ONE * randf_range(0.9, 1.35)

		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.12
		trunk_mesh.bottom_radius = 0.16
		trunk_mesh.height = 2.2
		trunk_mesh.radial_segments = 8
		trunk.mesh = trunk_mesh
		trunk.material_override = trunk_material
		trunk.position.y = 1.1
		tree.add_child(trunk)

		var canopy := MeshInstance3D.new()
		var canopy_mesh := SphereMesh.new()
		canopy_mesh.radius = 0.7
		canopy_mesh.height = 1.2
		canopy_mesh.radial_segments = 12
		canopy_mesh.rings = 10
		canopy.mesh = canopy_mesh
		canopy.material_override = canopy_material
		canopy.position.y = 2.6
		tree.add_child(canopy)

		add_child(tree)
		tree.owner = self

# Helper function to recursively search up the scene tree for a Path3D node
func _find_path_upwards(current_node: Node) -> Path3D:
	var parent := current_node.get_parent()
	if parent == null:
		return null
	
	# Look through the parent's children first
	for child in parent.get_children():
		if child is Path3D:
			return child
			
	# If not found, go up another level
	return _find_path_upwards(parent)

# Helper function to recursively search up the scene tree for a Terrain3D node
func _find_terrain_upwards(current_node: Node) -> Terrain3D:
	var parent := current_node.get_parent()
	if parent == null:
		return null
		
	var found = parent.find_child("Terrain3D", true, false)
	if found is Terrain3D:
		return found
		
	return _find_terrain_upwards(parent)
