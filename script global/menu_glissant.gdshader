shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    float amount = progress * 0.05; // Force de la déformation
    vec2 uv = SCREEN_UV;
    
    // Création de l'onde
    uv.x += sin(uv.y * 20.0 + progress * 10.0) * amount;
    uv.y += cos(uv.x * 20.0 + progress * 10.0) * amount;
    
    vec4 color = texture(SCREEN_TEXTURE, uv);
    
    // On fait devenir l'écran bleu/noir à la fin de la transition
	vec4 water_color = vec4(0.0, 0.0, 0.0, 1.0);
	COLOR = mix(color, water_color, progress);
}