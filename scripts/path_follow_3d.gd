extends Node3D

@export var path: Path3D

func _ready() -> void:
	if path == null:
		return

	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = path.curve.get_baked_points()

	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_LINE_STRIP, arr)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.WHITE

	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	add_child(mi)
