shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float sway_speed : hint_range(0.0, 5.0) = 0.8;
uniform float sway_strength : hint_range(0.0, 8.0) = 2.0;

void fragment() {
    vec2 pixel_size = TEXTURE_PIXEL_SIZE;
    float height_factor = 1.0 - UV.y;
    vec2 noise_uv = vec2(UV.x * 3.0 - TIME * sway_speed, UV.y * 2.0);
    float noise = texture(noise_texture, noise_uv).r;
    float offset = (noise * 2.0 - 1.0) * sway_strength * height_factor;
    vec2 displaced_uv = UV + vec2(offset * pixel_size.x, 0.0);
    COLOR = texture(TEXTURE, displaced_uv);
}
