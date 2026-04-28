shader_type canvas_item;

void fragment() {
    // Fait défiler la texture très lentement
    // Tu peux ajuster la vitesse en modifiant 0.01 et 0.005
    vec2 moving_uv = UV + vec2(TIME * 0.01, TIME * 0.005);
    
    // Ajoute une petite ondulation (Wave effect)
    // Tu peux aussi supprimer ces deux lignes si tu préfères un défilement simple
    moving_uv.x += sin(TIME * 0.5 + UV.y * 10.0) * 0.002;
    moving_uv.y += cos(TIME * 0.5 + UV.x * 10.0) * 0.002;

    COLOR = texture(TEXTURE, moving_uv);
}