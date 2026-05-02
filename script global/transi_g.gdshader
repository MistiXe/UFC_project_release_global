shader_type canvas_item;

uniform float circle_size : hint_range(0.0, 1.05) = 1.05;
uniform float screen_width = 1153.0; // À ajuster selon ta résolution
uniform float screen_height = 648.0;

void fragment() {
    float ratio = screen_width / screen_height;
    vec2 uv = UV;
    uv.x -= 0.5;
    uv.x *= ratio;
    uv.x += 0.5;
    
    float dist = distance(uv, vec2(0.5, 0.5));
    COLOR.a = step(circle_size, dist);
}