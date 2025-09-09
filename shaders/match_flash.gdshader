shader_type canvas_item;

uniform float flash_intensity : hint_range(0.0, 2.0) = 1.5;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Efecto de flash cuando hay match
	float flash = flash_progress * flash_intensity;
	vec3 final_color = mix(tex_color.rgb, flash_color.rgb, flash * tex_color.a);
	
	COLOR = vec4(final_color, tex_color.a);
}
