@tool
extends EditorScript

func _run():
	var root = EditorInterface.get_edited_scene_root()
	var visited: Array[int] = []
	toggle_recursive(root, visited)

func toggle_recursive(node: Node, visited: Array[int]) -> void:
	var mat: Material = null

	if node is TileMapLayer:
		mat = node.material
	elif node is CanvasItem:
		mat = node.material

	if mat and mat is ShaderMaterial:
		var id = mat.get_instance_id()
		if id not in visited:
			visited.append(id)
			var sm = mat as ShaderMaterial
			if sm.get_shader_parameter("shader_enabled") != null:
				var current = sm.get_shader_parameter("shader_enabled")
				sm.set_shader_parameter("shader_enabled", !current)
				print("Toggled: ", node.name)

	for child in node.get_children():
		toggle_recursive(child, visited)
