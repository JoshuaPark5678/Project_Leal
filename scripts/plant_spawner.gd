# Plant Spawner.gd
extends Node2D

@export var spawn_layer: TileMapLayer
@export var sprite_texture: Texture2D
@export var frame_count: int = 8
@export var frame_size: Vector2 = Vector2(16, 16)
@export var coverage: float = 0.65
@export var scale_min: float = 0.8
@export var scale_max: float = 1.3
@export var offset_range: float = 6.0
@export var shade_material: ShaderMaterial

func _ready() -> void:
	_spawn()

func _spawn() -> void:
	if not spawn_layer:
		push_error("VegetationSpawner: no spawn layer assigned")
		return

	var cells = spawn_layer.get_used_cells()
	if cells.is_empty():
		return

	# sort cells by frame
	var frame_cells: Array = []
	for i in range(frame_count):
		frame_cells.append([])

	for cell in cells:
		if randf() <= coverage:
			var frame = randi() % frame_count
			frame_cells[frame].append(cell)

	# one MultiMeshInstance2D per frame
	for frame in range(frame_count):
		var instances = frame_cells[frame]
		if instances.is_empty():
			continue

		var mmi = MultiMeshInstance2D.new()
		add_child(mmi)

		# build mesh with correct UVs baked in for this frame
		var mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_2D
		mm.mesh = _build_quad_mesh_for_frame(frame)
		mm.instance_count = instances.size()

		mmi.multimesh = mm
		mmi.texture = sprite_texture

		if shade_material:
			mmi.material = shade_material

		for i in range(instances.size()):
			var cell = instances[i]
			var base_pos = spawn_layer.map_to_local(cell)
			var offset = Vector2(
				randf_range(-offset_range, offset_range),
				randf_range(-offset_range, offset_range)
			)
			var s = randf_range(scale_min, scale_max)
			var t = Transform2D()
			t = t.scaled(Vector2(s, s))
			t.origin = base_pos + offset
			mm.set_instance_transform_2d(i, t)

func _build_quad_mesh_for_frame(frame: int) -> Mesh:
	var sheet_cols = int(sprite_texture.get_width() / frame_size.x)
	var frame_x = (frame % sheet_cols) * frame_size.x / sprite_texture.get_width()
	var frame_y = (frame / sheet_cols) * frame_size.y / sprite_texture.get_height()
	var frame_w = frame_size.x / sprite_texture.get_width()
	var frame_h = frame_size.y / sprite_texture.get_height()

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var hw = frame_size.x * 0.5
	var hh = frame_size.y * 0.5

	# two triangles making a quad with correct UVs baked in
	st.set_uv(Vector2(frame_x, frame_y));             st.add_vertex(Vector3(-hw, -hh, 0))
	st.set_uv(Vector2(frame_x + frame_w, frame_y));   st.add_vertex(Vector3(hw, -hh, 0))
	st.set_uv(Vector2(frame_x, frame_y + frame_h));   st.add_vertex(Vector3(-hw, hh, 0))

	st.set_uv(Vector2(frame_x + frame_w, frame_y));   st.add_vertex(Vector3(hw, -hh, 0))
	st.set_uv(Vector2(frame_x + frame_w, frame_y + frame_h)); st.add_vertex(Vector3(hw, hh, 0))
	st.set_uv(Vector2(frame_x, frame_y + frame_h));   st.add_vertex(Vector3(-hw, hh, 0))

	return st.commit()
