extends Node

# Call this function from anywhere to change all materials in the active scene
func change_project_albedo(new_color: Color) -> void:
	var current_scene = get_tree().current_scene
	if current_scene:
		_apply_color_recursive(current_scene, new_color)

# Helper function to walk down the node tree
func _apply_color_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		# Check for a material override first
		if node.material_override is StandardMaterial3D:
			node.material_override.albedo_color = color
		# Otherwise, check the material inside the mesh itself
		elif node.mesh and node.mesh.surface_get_material(0) is StandardMaterial3D:
			var mat = node.mesh.surface_get_material(0) as StandardMaterial3D
			mat.albedo_color = color
			
	# Keep digging down into the node's children
	for child in node.get_children():
		_apply_color_recursive(child, color)
