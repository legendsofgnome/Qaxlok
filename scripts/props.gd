class_name Props
## Placeholder props built from simple shapes, in the prototype's colours and sizes.
## Each model faces +Z, the same as the browser prototype, so rotation.y = r lines up.
## Any of these can later be replaced by a model from Nomad Sculpt (see README).

const PLASTER := "#efe6d6"
const THATCH := "#e3c56e"
const WOOD := "#8a5a30"
const DARKWOOD := "#5e3b22"
const STONE := "#b4ada0"
const TERRACOTTA := "#c4693e"

static func mi(parent: Node3D, mesh: Mesh, color: String, pos := Vector3.ZERO, rot := Vector3.ZERO, ink := true, glow := 0.0) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Toon.mat(Toon.hex(color), ink, false, glow)
	m.position = pos
	m.rotation = rot
	parent.add_child(m)
	return m

static func cyl(top: float, bottom: float, h: float, seg := 20) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c

static func sph(r: float, h: float = -1.0, seg := 16) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h if h > 0.0 else r * 2.0
	s.radial_segments = seg
	s.rings = maxi(6, seg / 2)
	return s

static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b

static func solid(parent: Node3D, shape: Shape3D, pos := Vector3.ZERO) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = pos
	body.add_child(cs)
	parent.add_child(body)
	return body

static func cyl_shape(r: float, h: float) -> CylinderShape3D:
	var s := CylinderShape3D.new()
	s.radius = r
	s.height = h
	return s

static func box_shape(x: float, y: float, z: float) -> BoxShape3D:
	var s := BoxShape3D.new()
	s.size = Vector3(x, y, z)
	return s

# ---------------------------------------------------------------- buildings
static func hut(door_color: String) -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.9, 0.98, 1.05, 28), PLASTER, Vector3(0, 0.525, 0))
	mi(n, cyl(0.0, 1.45, 1.75, 28), THATCH, Vector3(0, 1.0 + 0.875, 0))
	# the door sits in front of the wall with a dark doorway behind it
	mi(n, box(0.66, 0.98, 0.3), DARKWOOD, Vector3(0, 0.49, 0.86), Vector3.ZERO, false)
	mi(n, box(0.56, 0.92, 0.06), door_color, Vector3(0, 0.46, 1.02))
	mi(n, sph(0.075), "#bfe6f5", Vector3(0, 0.62, 1.06), Vector3.ZERO, true, 0.6)
	for side in [-1.0, 1.0]:
		var a: float = side * 0.85
		mi(n, sph(0.12), "#bfe6f5", Vector3(sin(a) * 1.0, 0.6, cos(a) * 1.0), Vector3.ZERO, true, 0.4)
	mi(n, box(0.22, 0.75, 0.22), "#a85a40", Vector3(0.6, 1.65, -0.25))
	solid(n, cyl_shape(1.0, 2.0), Vector3(0, 1.0, 0))
	return n

static func qhouse() -> Node3D:
	var n := Node3D.new()
	# stone cottage with a red gabled roof
	mi(n, box(2.35, 1.02, 1.5), "#c9c2b0", Vector3(-1.32, 0.51, 0))
	var roof := PrismMesh.new()
	roof.size = Vector3(1.85, 0.8, 2.6)
	mi(n, roof, "#b9573a", Vector3(-1.32, 1.42, 0), Vector3(0, PI / 2, 0))
	mi(n, box(0.5, 0.9, 0.06), "#7a4f2b", Vector3(-1.32, 0.45, 0.78))
	# the round thatched cottage
	var hutn := hut("#7a4f2b")
	hutn.position = Vector3(0.95, 0, 0)
	n.add_child(hutn)
	# the round tower with its slate cap and pennant
	mi(n, cyl(0.54, 0.58, 2.6, 22), "#cfc8b6", Vector3(-1.65, 1.3, -0.95))
	mi(n, cyl(0.0, 0.72, 1.2, 22), "#6b7a8c", Vector3(-1.65, 3.15, -0.95))
	mi(n, box(0.42, 0.2, 0.02), "#f4ead2", Vector3(-1.44, 4.2, -0.95))
	solid(n, box_shape(2.4, 2.0, 1.55), Vector3(-1.32, 1.0, 0))
	solid(n, cyl_shape(0.6, 3.0), Vector3(-1.65, 1.5, -0.95))
	return n

static func tower() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.8, 0.9, 5.2, 26), "#d8d0c0", Vector3(0, 2.6, 0))
	mi(n, cyl(0.0, 1.15, 1.8, 26), "#5a6f8c", Vector3(0, 6.1, 0))
	mi(n, box(0.6, 1.1, 0.12), "#7a4f2b", Vector3(0, 0.55, 0.86))
	mi(n, cyl(0.02, 0.02, 0.8, 6), "#4a4a52", Vector3(0, 7.3, 0))
	mi(n, box(0.5, 0.06, 0.06), "#c9a24a", Vector3(0.2, 7.55, 0))
	solid(n, cyl_shape(0.92, 6.0), Vector3(0, 3.0, 0))
	return n

static func wall() -> Node3D:
	var n := Node3D.new()
	mi(n, box(1.02, 0.9, 0.42), STONE, Vector3(0, 0.45, 0))
	solid(n, box_shape(1.02, 1.0, 0.42), Vector3(0, 0.5, 0))
	return n

static func fence_post() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.05, 0.06, 0.8, 8), WOOD, Vector3(0, 0.4, 0))
	return n

static func gate() -> Node3D:
	var n := Node3D.new()
	for x in [-0.9, 0.9]:
		mi(n, cyl(0.09, 0.1, 1.3, 10), DARKWOOD, Vector3(x, 0.65, 0))
	mi(n, box(1.7, 0.12, 0.08), WOOD, Vector3(0, 0.9, 0))
	mi(n, box(1.7, 0.12, 0.08), WOOD, Vector3(0, 0.45, 0))
	return n

static func bridge() -> Node3D:
	var n := Node3D.new()
	mi(n, box(4.4, 0.14, 1.3), WOOD, Vector3(0, 0.12, 0))
	for z in [-0.6, 0.6]:
		mi(n, box(4.4, 0.08, 0.08), DARKWOOD, Vector3(0, 0.6, z))
		for x in [-2.0, -0.7, 0.7, 2.0]:
			mi(n, cyl(0.04, 0.04, 0.5, 6), DARKWOOD, Vector3(x, 0.37, z))
	solid(n, box_shape(4.4, 0.14, 1.3), Vector3(0, 0.12, 0))
	return n

static func pier() -> Node3D:
	var n := Node3D.new()
	mi(n, box(1.24, 0.12, 3.2), WOOD, Vector3(0, 0.2, 0))
	for x in [-0.55, 0.55]:
		for z in [-1.4, 0.0, 1.4]:
			mi(n, cyl(0.06, 0.06, 0.9, 8), DARKWOOD, Vector3(x, -0.15, z))
	solid(n, box_shape(1.24, 0.12, 3.2), Vector3(0, 0.2, 0))
	return n

# ---------------------------------------------------------------- small props
static func lantern() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.04, 0.05, 1.5, 8), DARKWOOD, Vector3(0, 0.75, 0))
	mi(n, box(0.5, 0.05, 0.05), DARKWOOD, Vector3(0.22, 1.45, 0))
	mi(n, box(0.16, 0.22, 0.16), "#ffcf6a", Vector3(0.42, 1.28, 0), Vector3.ZERO, true, 1.2)
	solid(n, cyl_shape(0.08, 1.5), Vector3(0, 0.75, 0))
	return n

static func stump() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.24, 0.3, 0.32, 14), "#7a5636", Vector3(0, 0.16, 0))
	mi(n, cyl(0.235, 0.235, 0.02, 14), "#d8b888", Vector3(0, 0.33, 0), Vector3.ZERO, false)
	solid(n, cyl_shape(0.3, 0.4), Vector3(0, 0.2, 0))
	return n

static func stool() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.2, 0.2, 0.06, 14), WOOD, Vector3(0, 0.42, 0))
	for i in 3:
		var a := TAU * i / 3.0
		mi(n, cyl(0.025, 0.03, 0.42, 6), DARKWOOD, Vector3(cos(a) * 0.13, 0.21, sin(a) * 0.13))
	return n

static func cauldron() -> Node3D:
	var n := Node3D.new()
	mi(n, sph(0.42, 0.62, 20), "#2a2628", Vector3(0, 0.34, 0))
	mi(n, cyl(0.34, 0.34, 0.03, 20), "#7fe07a", Vector3(0, 0.6, 0), Vector3.ZERO, false, 0.8)
	solid(n, cyl_shape(0.42, 0.7), Vector3(0, 0.35, 0))
	return n

static func sign_post() -> Node3D:
	var n := Node3D.new()
	mi(n, cyl(0.04, 0.05, 1.1, 8), DARKWOOD, Vector3(0, 0.55, 0))
	mi(n, box(0.7, 0.32, 0.06), WOOD, Vector3(0, 0.95, 0))
	return n

static func jug(c := "#8fc7c0") -> Node3D:
	var n := Node3D.new()
	mi(n, sph(0.16, 0.3, 12), c, Vector3(0, 0.15, 0))
	mi(n, cyl(0.05, 0.06, 0.12, 10), c, Vector3(0, 0.33, 0))
	return n

static func planks() -> Node3D:
	var n := Node3D.new()
	for i in 4:
		mi(n, box(1.4, 0.06, 0.18), WOOD, Vector3(0, 0.03 + i * 0.065, -0.3 + i * 0.03), Vector3(0, i * 0.08, 0))
	return n

# ---------------------------------------------------------------- interactables
static func pot(broken: bool, is_barrel: bool) -> Node3D:
	var n := Node3D.new()
	var col := DARKWOOD if is_barrel else TERRACOTTA
	if broken:
		if is_barrel:
			mi(n, cyl(0.2, 0.2, 0.18, 14), "#8a5a30", Vector3(0, 0.09, 0))
		else:
			mi(n, sph(0.2, 0.2, 12), col, Vector3(0, 0.06, 0))
		for i in 4:
			var a := TAU * i / 4.0 + 0.4
			mi(n, box(0.12, 0.03, 0.08), col, Vector3(cos(a) * 0.34, 0.02, sin(a) * 0.34), Vector3(0, a, 0.3))
	else:
		if is_barrel:
			mi(n, cyl(0.21, 0.21, 0.55, 16), "#8a5a30", Vector3(0, 0.275, 0))
			mi(n, cyl(0.225, 0.225, 0.04, 16), "#3d3a36", Vector3(0, 0.12, 0))
			mi(n, cyl(0.225, 0.225, 0.04, 16), "#3d3a36", Vector3(0, 0.43, 0))
		else:
			mi(n, sph(0.22, 0.4, 14), col, Vector3(0, 0.2, 0))
			mi(n, cyl(0.08, 0.1, 0.1, 12), col, Vector3(0, 0.42, 0))
	return n

static func chest(open: bool) -> Node3D:
	var n := Node3D.new()
	mi(n, box(0.7, 0.36, 0.46), "#8a5a30", Vector3(0, 0.18, 0))
	mi(n, box(0.72, 0.05, 0.48), "#c9a24a", Vector3(0, 0.36, 0), Vector3.ZERO, false)
	var hinge := Node3D.new()
	hinge.name = "Lid"
	hinge.position = Vector3(0, 0.38, -0.23)
	n.add_child(hinge)
	mi(hinge, box(0.7, 0.18, 0.46), "#9a6a38", Vector3(0, 0.09, 0.23))
	mi(hinge, box(0.08, 0.1, 0.03), "#c9a24a", Vector3(0, 0.06, 0.47), Vector3.ZERO, false)
	if open:
		hinge.rotation.x = -1.9
	solid(n, box_shape(0.7, 0.5, 0.46), Vector3(0, 0.25, 0))
	return n

static func shrine(state: int) -> Node3D:
	var n := Node3D.new()
	if state == 0:
		mi(n, cyl(0.32, 0.38, 0.2, 14), "#9a968c", Vector3(0, 0.1, 0))
		mi(n, cyl(0.12, 0.14, 0.45, 10), "#9a968c", Vector3(0.25, 0.15, 0.1), Vector3(0, 0, 1.3))
		mi(n, sph(0.2, 0.18, 12), "#9a968c", Vector3(-0.3, 0.06, -0.2))
	else:
		mi(n, cyl(0.32, 0.38, 0.2, 14), "#b8b2a4", Vector3(0, 0.1, 0))
		mi(n, cyl(0.12, 0.14, 0.7, 10), "#b8b2a4", Vector3(0, 0.55, 0))
		mi(n, cyl(0.3, 0.16, 0.16, 14), "#b8b2a4", Vector3(0, 0.98, 0))
		if state == 2:
			mi(n, sph(0.16), "#ffd36a", Vector3(0, 1.12, 0), Vector3.ZERO, false, 1.6)
			var l := OmniLight3D.new()
			l.light_color = Color(1.0, 0.82, 0.45)
			l.omni_range = 4.0
			l.light_energy = 1.4
			l.position = Vector3(0, 1.3, 0)
			n.add_child(l)
	solid(n, cyl_shape(0.38, 1.2), Vector3(0, 0.6, 0))
	return n

static func gem() -> Node3D:
	var n := Node3D.new()
	var p := PrismMesh.new()
	p.size = Vector3(0.22, 0.26, 0.22)
	mi(n, p, "#5fd0ff", Vector3(0, 0.35, 0), Vector3.ZERO, true, 0.7)
	mi(n, p, "#5fd0ff", Vector3(0, 0.09, 0), Vector3(PI, 0, 0), true, 0.7)
	return n

static func herb(kind: String) -> Node3D:
	var cols := {"rosepuff": "#f08ab8", "mint": "#7fd07a", "dewbell": "#9ad0f0", "sunpetal": "#ffd34a",
		"redcap": "#d9483a", "inkcap": "#4a4a6a", "moonshroom": "#c8c0ff", "apple": "#d8402e"}
	var n := Node3D.new()
	var c: String = cols.get(kind, "#f0a0c0")
	if kind == "apple":
		mi(n, sph(0.09), c, Vector3(0, 0.09, 0))
	elif kind in ["redcap", "inkcap", "moonshroom"]:
		mi(n, cyl(0.025, 0.03, 0.14, 6), "#f4efe2", Vector3(0, 0.07, 0))
		mi(n, sph(0.09, 0.08, 10), c, Vector3(0, 0.15, 0))
	else:
		mi(n, cyl(0.012, 0.012, 0.22, 5), "#4a8a3a", Vector3(0, 0.11, 0), Vector3.ZERO, false)
		mi(n, sph(0.06), c, Vector3(0, 0.24, 0))
	return n
