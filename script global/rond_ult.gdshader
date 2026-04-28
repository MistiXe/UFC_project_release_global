shader_type canvas_item;

uniform float pulse_weight : hint_range(0.0, 1.0) = 0.0; 

void fragment() {
    float d = distance(UV, vec2(0.5));
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Masque circulaire
    tex_color.a *= step(d, 0.5);
    
    // Au lieu d'ajouter du blanc, on mélange la couleur originale 
    // avec une version plus claire/brillante de façon fluide
    vec3 bright_color = tex_color.rgb * 1.5; 
    vec3 final_rgb = mix(tex_color.rgb, bright_color, pulse_weight);
    
    COLOR = vec4(final_rgb, tex_color.a);
}