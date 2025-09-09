shader_type canvas_item;

uniform float glow_strength : hint_range(0.0, 2.0) = 1.0;
uniform float glow_speed : hint_range(0.1, 5.0) = 2.0;
uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform bool is_special : hint_boolean = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	if (is_special) {
		// Efecto de brillo pulsante para fichas especiales
		float glow = sin(TIME * glow_speed) * 0.5 + 0.5;
		vec3 glow_effect = glow_color.rgb * glow * glow_strength;
		
		// Agregar brillo manteniendo el color original
		COLOR = vec4(tex_color.rgb + glow_effect * tex_color.a, tex_color.a);
	} else {
		COLOR = tex_color;
	}
}
