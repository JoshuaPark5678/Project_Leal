extends StaticBody2D

@export var active := true

@export var y_offset : float = 0.0

var fog_materials: Array[ShaderMaterial] = []

func _ready():
    find_all_fog_materials(get_tree().root)
    print("Campfire found ", fog_materials.size(), " materials")

func find_all_fog_materials(node: Node) -> void:
    for child in node.get_children():
        if child.get("material") and child.material is ShaderMaterial:
            var mat = child.material as ShaderMaterial
            if mat.shader and mat.get_shader_parameter("campfire_position") != null:
                fog_materials.append(mat)
        find_all_fog_materials(child)

func _process(_delta):
    var viewport = get_viewport()
    if not viewport:
        return
    var canvas_transform = viewport.get_canvas_transform()
    var screen_pos = canvas_transform * (global_position + Vector2(0, y_offset))
    for mat in fog_materials:
        mat.set_shader_parameter("campfire_position", screen_pos)
        mat.set_shader_parameter("campfire_active", active)