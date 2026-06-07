extends MultiMeshInstance3D

@export var tree_scene := preload("res://scenes/tree.tscn")
@export var count := 300
@export var area_size := 50.0

func _ready():
	# Instanz der Szene erstellen
	var tree_instance := tree_scene.instantiate()
	
	# Baum-Stamm als MeshInstance3D abrufen
	var mesh_instance := tree_instance.get_node("Stamm") as MeshInstance3D
	var mesh : Mesh = mesh_instance.mesh  # Typ explizit angeben

	# MultiMesh erstellen
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = count
	mm.mesh = mesh
	multimesh = mm
	
	randomize()
	for i in range(count):
		var t := Transform3D()
		t.origin = Vector3(
			randf_range(-area_size, area_size),
			0,
			randf_range(-area_size, area_size)
		)
		t.basis = Basis(Vector3.UP, randf_range(0, TAU))
		t = t.scaled(Vector3.ONE * randf_range(0.8, 1.2))
		mm.set_instance_transform(i, t)
