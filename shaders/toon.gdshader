// Flat painted cel shading: one flat colour per surface (optionally times the
// mesh's vertex colours, e.g. vertex paint from Nomad Sculpt), lit in two soft
// bands, with a gentle rim light. No surface texture, no bumps.
shader_type spatial;
render_mode cull_back, specular_disabled;

uniform vec4 albedo : source_color = vec4(1.0);
uniform bool use_vertex_color = false;
uniform float band_softness : hint_range(0.01, 0.5) = 0.16;
uniform float shadow_floor : hint_range(0.0, 1.0) = 0.42;
uniform vec4 rim_color : source_color = vec4(1.0, 0.96, 0.85, 1.0);
uniform float rim_amount : hint_range(0.0, 1.0) = 0.12;
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec3 c = albedo.rgb;
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = emission_color.rgb + rim_color.rgb * c * rim_amount * smoothstep(0.55, 0.85, fres);
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(0.0, band_softness, ndl) * 0.55 + smoothstep(0.38, 0.38 + band_softness, ndl) * 0.45;
	lit = mix(shadow_floor * 0.35, 1.0, lit * ATTENUATION);
	DIFFUSE_LIGHT += lit * LIGHT_COLOR / PI;
}
