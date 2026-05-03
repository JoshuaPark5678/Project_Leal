shader_type canvas_item;

void vertex() {
    // custom data holds UV offset per instance
    vec2 uv_offset = vec2(INSTANCE_CUSTOM.x, INSTANCE_CUSTOM.y);
    vec2 uv_scale = vec2(INSTANCE_CUSTOM.z, INSTANCE_CUSTOM.w);
    UV = uv_offset + UV * uv_scale;
}

void fragment() {
    COLOR = texture(TEXTURE, UV);
    if (COLOR.a < 0.1) discard;
}