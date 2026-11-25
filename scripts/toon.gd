class_name Toon
## Shared materials: flat cel-shaded colours with an ink outline (an inverted hull drawn as a second pass).

const OUTLINE_COLOR := Color(0.16, 0.10, 0.07)
static var _shader: Shader
static var _cache := {}
static var _outline: StandardMaterial3D

static func shader() -> Shader:
	if _shader == null:
		_shader = load("res://shaders/toon.gdshader")
	return _shader

static func outline(width: float = 0.018) -> StandardMaterial3D:
	if _outline == null:
		_outline = StandardMaterial3D.new()
		_outline.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_outline.cull_mode = BaseMaterial3D.CULL_FRONT
		_outline.albedo_color = OUTLINE_COLOR
		_outline.grow = true
		_outline.grow_amount = width
	return _outline

## A flat colour material. `ink` adds the outline pass; `glow` makes it shine at night.
static func mat(c: Color, ink: bool = true, vertex_color: bool = false, glow: float = 0.0) -> ShaderMaterial:
	var key := "%s|%s|%s|%s" % [c.to_html(), ink, vertex_color, glow]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = shader()
	m.set_shader_parameter("albedo", c)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	if glow > 0.0:
		m.set_shader_parameter("emission_color", c * glow)
	if ink:
		m.next_pass = outline()
	_cache[key] = m
	return m

static func hex(s: String) -> Color:
	return Color.html(s)

## Give every mesh in an imported model (e.g. a .glb from Nomad Sculpt) the toon look,
## keeping its vertex paint and the colour of its own material.
static func apply_to_model(root: Node) -> void:
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var base := Color.WHITE
			var src := mi.mesh.surface_get_material(i)
			if src is BaseMaterial3D:
				base = (src as BaseMaterial3D).albedo_color
			mi.set_surface_override_material(i, mat(base, true, true))
