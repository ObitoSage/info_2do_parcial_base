shader_type canvas_item;

uniform float time_speed : hint_range(0.1, 3.0) = 1.0;
uniform vec4 color_top : source_color = vec4(0.2, 0.1, 0.6, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.8, 0.2, 0.8, 1.0);
uniform float wave_strength : hint_range(0.0, 0.1) = 0.02;

void fragment() {
	// Coordenadas UV animadas
	vec2 uv = UV;
	
	// Ondas sutiles
	uv.x += sin(uv.y * 10.0 + TIME * time_speed) * wave_strength;
	uv.y += cos(uv.x * 8.0 + TIME * time_speed * 0.8) * wave_strength;
	
	// Gradiente vertical animado
	float gradient = uv.y + sin(TIME * time_speed * 0.5) * 0.1;
	
	// Mezcla de colores
	vec4 final_color = mix(color_top, color_bottom, gradient);
	
	// Añadir un poco de brillo sutil
	float sparkle = sin(uv.x * 50.0 + TIME * time_speed * 2.0) * 
	               cos(uv.y * 50.0 + TIME * time_speed * 1.5) * 0.1;
	final_color.rgb += vec3(sparkle);
	
	COLOR = final_color;
}
