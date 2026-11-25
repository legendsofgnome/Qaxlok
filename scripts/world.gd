class_name World
extends Node3D
## Builds the village from data/village.json: the same map you made in the prototype's editor.
## Terrain heights, ground types, every building, prop, villager, sheep and herb.

const HS := 0.3            # one height step in the map = 0.3 world units (as in the prototype)
const WATER_BED := -0.45
const WATER_SURF := -0.06
const SUB := 2              # terrain vertices per tile edge

const GROUND_COL := {"g": "#79b04f", "p": "#cdb07a", "s": "#e3cf9c", "w": "#6f8a5e", "m": "#5f9a4f"}

var W := 0
var H := 0
var ground: Array = []
var height: Array = []
var objects: Array = []
var interactables: Array[Interactable] = []
var spawn := Vector3(10, 0, 40)
var spawn_r := 0.0
var walk_rects: Array = []   # bridges and piers: [Transform3D, half_x, half_z]
var animals: Array = []
var npcs: Array = []

func _ready() -> void:
	var f := FileAccess.open("res://data/village.json", FileAccess.READ)
	var L: Dictionary = JSON.parse_string(f.get_as_text())
	W = int(L["w"])
	H = int(L["h"])
	ground = L["ground"]
	height = L["height"]
	objects = L["objects"]
	_build_terrain()
	_build_water()
	_build_objects()

# ---------------------------------------------------------------- terrain
func tile(x: int, z: int) -> String:
	if x < 0 or z < 0 or x >= W or z >= H:
		return "g"
	return (ground[z] as String)[x]

func tile_h(x: int, z: int) -> float:
	x = clampi(x, 0, W - 1)
	z = clampi(z, 0, H - 1)
	if tile(x, z) == "w":
		return WATER_BED
	return float(height[z][x]) * HS

## Height at a tile corner: the average of the (up to four) tiles that meet there.
func corner_h(cx: int, cz: int) -> float:
	var s := 0.0
	var n := 0
	var wet := false
	for dz in [-1, 0]:
		for dx in [-1, 0]:
			var x: int = cx + dx
			var z: int = cz + dz
			if x < 0 or z < 0 or x >= W or z >= H:
				continue
			if tile(x, z) == "w":
				wet = true
			s += tile_h(x, z)
			n += 1
	var h: float = s / float(maxi(n, 1))
	return minf(h, 0.0) if wet else h

func height_at(x: float, z: float) -> float:
	x = clampf(x, 0.0, W - 0.001)
	z = clampf(z, 0.0, H - 0.001)
	var ix := int(floor(x))
	var iz := int(floor(z))
	var u := x - ix
	var v := z - iz
	var a := corner_h(ix, iz)
	var b := corner_h(ix + 1, iz)
	var c := corner_h(ix, iz + 1)
	var d := corner_h(ix + 1, iz + 1)
	return lerpf(lerpf(a, b, u), lerpf(c, d, u), v)

func corner_col(cx: int, cz: int) -> Color:
	var col := Color(0, 0, 0)
	var n := 0
	for dz in [-1, 0]:
		for dx in [-1, 0]:
			var t := tile(clampi(cx + dx, 0, W - 1), clampi(cz + dz, 0, H - 1))
			col += Toon.hex(GROUND_COL.get(t, "#79b04f"))
			n += 1
	# vertex colours go to the shader as-is (linear), so convert from the usual sRGB hex colours
	return (col / n).srgb_to_linear()

func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := 1.0 / SUB
	for z in H * SUB:
		for x in W * SUB:
			var quad := []
			for c in [[0, 0], [1, 0], [1, 1], [0, 1]]:
				var px: float = (x + c[0]) * step
				var pz: float = (z + c[1]) * step
				var cx := int(round(px))
				var cz := int(round(pz))
				var col := corner_col(cx, cz) if abs(px - cx) < 0.01 and abs(pz - cz) < 0.01 else _mid_col(px, pz)
				quad.append([Vector3(px, height_at(px, pz), pz), col])
			for k in [0, 1, 2, 0, 2, 3]:
				st.set_color(quad[k][1])
				st.add_vertex(quad[k][0])
	st.generate_normals()
	var mesh := st.commit()
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = Toon.mat(Color.WHITE, false, true)
	m.name = "Terrain"
	add_child(m)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	add_child(body)

func _mid_col(px: float, pz: float) -> Color:
	var a := corner_col(int(floor(px)), int(floor(pz)))
	var b := corner_col(int(ceil(px)), int(floor(pz)))
	var c := corner_col(int(floor(px)), int(ceil(pz)))
	var d := corner_col(int(ceil(px)), int(ceil(pz)))
	var u := px - floorf(px)
	var v := pz - floorf(pz)
	return a.lerp(b, u).lerp(c.lerp(d, u), v)

func _build_water() -> void:
	var p := PlaneMesh.new()
	p.size = Vector2(W + 40, H + 40)
	var m := MeshInstance3D.new()
	m.mesh = p
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.36, 0.62, 0.78, 0.78)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.15
	mat.metallic_specular = 0.6
	m.material_override = mat
	m.position = Vector3(W / 2.0, WATER_SURF, H / 2.0)
	m.name = "Water"
	add_child(m)

## Can Qaxlok stand here? Not in deep water, unless he is on a bridge or pier.
func is_walkable(x: float, z: float) -> bool:
	if x < 0.3 or z < 0.3 or x > W - 0.3 or z > H - 0.3:
		return false
	for r in walk_rects:
		var local: Vector3 = (r[0] as Transform3D).affine_inverse() * Vector3(x, 0, z)
		if abs(local.x) <= r[1] and abs(local.z) <= r[2]:
			return true
	return tile(int(floor(x)), int(floor(z))) != "w"

# ---------------------------------------------------------------- objects
func _place(n: Node3D, o: Dictionary, y_off := 0.0) -> Node3D:
	var x := float(o["x"])
	var z := float(o["z"])
	n.position = Vector3(x, height_at(x, z) + y_off, z)
	n.rotation.y = float(o.get("r", 0)) * PI / 4.0
	var s := float(o.get("s", 1))
	n.scale = Vector3.ONE * s
	add_child(n)
	return n

func _interactable(kind: String, o: Dictionary, idx: int) -> Interactable:
	var it := Interactable.new()
	it.kind = kind
	it.id = "%s_%d" % [kind, idx]
	_place(it, o)
	interactables.append(it)
	return it

func _build_objects() -> void:
	var trees: Array[Transform3D] = []
	var apple_trees: Array[Transform3D] = []
	var broken_left := 2
	var pal := ["#d9483a", "#3b8a5a", "#8a5ab8", "#d9893a"]
	for i in objects.size():
		var o: Dictionary = objects[i]
		var t: String = o["t"]
		match t:
			"wizard":
				spawn = Vector3(float(o["x"]), 0, float(o["z"]))
				spawn_r = float(o.get("r", 0)) * PI / 4.0
			"hut":
				_place(Props.hut(o.get("c", "#7a4f2b")), o)
			"qhouse":
				_place(Props.qhouse(), o)
			"tower":
				_place(Props.tower(), o)
			"wall":
				_place(Props.wall(), o)
			"fencePost":
				_place(Props.fence_post(), o)
			"gate":
				_place(Props.gate(), o)
			"bridge":
				var b := _walkway(o, Vector3.RIGHT, 2.2, 0.65, 0.18, true)
				walk_rects.append([b.transform, 2.6, 0.65])
			"pier":
				var p := _walkway(o, Vector3.BACK, 1.6, 0.62, 0.0, false)
				walk_rects.append([p.transform, 0.62, 2.0])
			"lantern":
				_place(Props.lantern(), o)
			"stump":
				_place(Props.stump(), o)
			"stool":
				_place(Props.stool(), o)
			"cauldron":
				_place(Props.cauldron(), o)
			"sign":
				_place(Props.sign_post(), o)
			"jug", "flask":
				_place(Props.jug("#8fc7c0" if t == "jug" else "#c8a0e0"), o)
			"planks", "buildsite":
				_place(Props.planks(), o)
			"tree", "talltree":
				trees.append(_tree_xf(o))
			"appletree":
				apple_trees.append(_tree_xf(o))
			"pot", "barrel":
				var it := _interactable("pot", o, i)
				var broken := broken_left > 0 or o.has("q")
				broken_left -= 1
				if Save.has_in("mended", it.id):
					broken = false
				it.state = 0 if broken else 1
				it.extra = {"barrel": t == "barrel"}
				it.set_visual(Props.pot(broken, t == "barrel"))
				it.reach = 1.3
			"chest":
				var it := _interactable("chest", o, i)
				it.state = 1 if Save.has_in("chests", it.id) else 0
				it.extra = {"loot": o.get("n", "gems")}
				it.set_visual(Props.chest(it.state == 1))
				it.reach = 1.4
			"shrine":
				var it := _interactable("shrine", o, i)
				it.state = int(Save.data["shrines"].get(it.id, 0))
				it.set_visual(Props.shrine(it.state))
				it.reach = 1.6
			"gem":
				var it := _interactable("gem", o, i)
				if Save.has_in("picked", it.id):
					it.queue_free()
					interactables.erase(it)
				else:
					it.set_visual(Props.gem())
					it.reach = 1.1
			"rosepuff", "mint", "dewbell", "sunpetal", "redcap", "inkcap", "moonshroom", "apple":
				var it := _interactable("herb", o, i)
				if Save.has_in("picked", it.id):
					it.queue_free()
					interactables.erase(it)
				else:
					it.extra = {"herb": t}
					it.set_visual(Props.herb(t))
					it.reach = 1.0
			"gnome":
				var it := _interactable("npc", o, i)
				var nm: String = o.get("n", "Gnome")
				var hat: String = pal[absi(hash(nm)) % pal.size()]
				var g := Gnome.make(nm, o.get("c", "#c0623a"), hat)
				it.set_visual(g)
				it.label = nm
				it.extra = {"lines": Dialogue.lines(nm), "home": Vector3(float(o["x"]), 0, float(o["z"]))}
				it.reach = 1.6
				npcs.append(it)
				var tag := Label3D.new()
				tag.text = nm
				tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				tag.position = Vector3(0, 1.45, 0)
				tag.font_size = 40
				tag.pixel_size = 0.004
				tag.outline_size = 10
				tag.modulate = Color(1, 1, 1, 0.9)
				it.add_child(tag)
			"sheep":
				var sh := _place(_sheep(), o)
				animals.append({"node": sh, "home": sh.position, "t": randf() * 10.0, "target": sh.position})
			"dog":
				var d := _place(_dog(), o)
				animals.append({"node": d, "home": d.position, "t": 0.0, "target": d.position, "fast": true})
	_multimesh_trees(trees, false)
	_multimesh_trees(apple_trees, true)

## A bridge or pier whose deck meets the ground exactly at its ends (so there is no lip to trip on),
## with a gentle arch over the water. `axis` is the walking direction in the object's own space.
func _walkway(o: Dictionary, axis: Vector3, half_len: float, half_w: float, arch: float, both_ends: bool) -> Node3D:
	var n := Node3D.new()
	var x0 := float(o["x"])
	var z0 := float(o["z"])
	n.position = Vector3(x0, 0, z0)
	n.rotation.y = float(o.get("r", 0)) * PI / 4.0
	add_child(n)
	var side := axis.cross(Vector3.UP).normalized()
	var ext := half_len + 0.45                    # run a little way onto the banks
	var w := func(t: float) -> Vector3: return n.transform * (axis * t)
	var ga := height_at(w.call(-ext).x, w.call(-ext).z)
	var gb := height_at(w.call(ext).x, w.call(ext).z) if both_ends else ga
	var top := maxf(maxf(ga, gb), WATER_SURF + 0.12)
	var N := 12
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts := []
	for i in N + 1:
		var u := float(i) / N
		var t := lerpf(-ext, ext, u)
		var base := lerpf(ga - 0.03, gb - 0.03, u)
		var y := maxf(base, top) + arch * sin(u * PI) if both_ends else lerpf(ga - 0.03, top, minf(u * 4.0, 1.0))
		pts.append(axis * t + Vector3(0, y, 0))
	for i in N:
		var a0: Vector3 = pts[i] - side * half_w
		var a1: Vector3 = pts[i] + side * half_w
		var b0: Vector3 = pts[i + 1] - side * half_w
		var b1: Vector3 = pts[i + 1] + side * half_w
		for v in [a0, b0, b1, a0, b1, a1]:
			st.add_vertex(v)
		# a little thickness under the deck, so it doesn't look paper thin
		var d := Vector3(0, -0.12, 0)
		for v in [a0 + d, a1 + d, b1 + d, a0 + d, b1 + d, b0 + d]:
			st.add_vertex(v)
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Toon.mat(Toon.hex(Props.WOOD))
	n.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	body.add_child(cs)
	n.add_child(body)
	# rails and posts (bridge) or posts (pier)
	for i in range(1, N, 2):
		var p: Vector3 = pts[i]
		for sgn in [-1.0, 1.0]:
			var post := Props.mi(n, Props.cyl(0.04, 0.05, 0.6 if both_ends else 1.0, 6), Props.DARKWOOD, p + side * (half_w - 0.05) * sgn + Vector3(0, 0.25 if both_ends else -0.3, 0))
			post.name = "Post"
	if both_ends:
		for sgn in [-1.0, 1.0]:
			for i in N:
				var q0: Vector3 = pts[i] + side * (half_w - 0.05) * sgn + Vector3(0, 0.55, 0)
				var q1: Vector3 = pts[i + 1] + side * (half_w - 0.05) * sgn + Vector3(0, 0.55, 0)
				var rail := Props.mi(n, Props.box(0.06, 0.06, q0.distance_to(q1) + 0.02), Props.DARKWOOD, (q0 + q1) * 0.5)
				rail.look_at_from_position(rail.position, q1, Vector3.UP)
				rail.position = (q0 + q1) * 0.5
	return n

func _tree_xf(o: Dictionary) -> Transform3D:
	var x := float(o["x"])
	var z := float(o["z"])
	var s := float(o.get("s", 1)) * (0.85 + fmod(abs(x * 7.13 + z * 3.7), 0.3))
	var b := Basis(Vector3.UP, fmod(x * 1.7 + z, TAU)).scaled(Vector3.ONE * s)
	# trees block the way
	var body := Props.solid(self, Props.cyl_shape(0.25 * s, 2.0), Vector3(x, height_at(x, z) + 1.0, z))
	body.name = "TreeTrunk"
	return Transform3D(b, Vector3(x, height_at(x, z), z))

func _multimesh_trees(xfs: Array[Transform3D], apples: bool) -> void:
	if xfs.is_empty():
		return
	var parts := [
		[Props.cyl(0.12, 0.17, 1.1, 10), "#7a5636", Vector3(0, 0.55, 0)],
		[Props.sph(0.85, 1.4, 16), "#5fa84a" if not apples else "#6db455", Vector3(0, 1.75, 0)],
		[Props.sph(0.55, 0.9, 12), "#73bb58" if not apples else "#80c565", Vector3(0.35, 2.25, 0.2)],
	]
	if apples:
		parts.append([Props.sph(0.09), "#d8402e", Vector3(0.62, 1.7, 0.45)])
		parts.append([Props.sph(0.09), "#d8402e", Vector3(-0.55, 1.95, 0.3)])
	for p in parts:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = p[0]
		mm.instance_count = xfs.size()
		for i in xfs.size():
			mm.set_instance_transform(i, xfs[i] * Transform3D(Basis(), p[2]))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Toon.mat(Toon.hex(p[1]))
		add_child(mmi)

func _sheep() -> Node3D:
	var n := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	n.add_child(body)
	Props.mi(body, Props.sph(0.34, 0.5, 14), "#f4efe6", Vector3(0, 0.34, 0))
	Props.mi(body, Props.sph(0.12, 0.22, 10), "#4d3f3a", Vector3(0, 0.4, 0.36))
	for lx in [-0.13, 0.13]:
		for lz in [-0.15, 0.15]:
			Props.mi(body, Props.cyl(0.03, 0.03, 0.14, 6), "#4d3f3a", Vector3(lx, 0.07, lz))
	return n

func _dog() -> Node3D:
	var n := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	n.add_child(body)
	Props.mi(body, Props.sph(0.12, 0.2, 12), "#2b2729", Vector3(0, 0.25, 0))
	Props.mi(body, Props.box(0.2, 0.18, 0.4), "#2b2729", Vector3(0, 0.25, -0.05))
	Props.mi(body, Props.sph(0.09), "#f1ede4", Vector3(0, 0.36, 0.22))
	for lx in [-0.065, 0.065]:
		for lz in [-0.12, 0.12]:
			Props.mi(body, Props.cyl(0.025, 0.025, 0.2, 6), "#f1ede4", Vector3(lx, 0.1, lz))
	return n

## Sheep drift around their spot; Winkle trots about. Their bodies bob while they move.
func _process(delta: float) -> void:
	for a in animals:
		var n: Node3D = a["node"]
		a["t"] -= delta
		if a["t"] <= 0.0:
			a["t"] = randf_range(2.0, 6.0)
			var r := 2.5 if not a.get("fast", false) else 6.0
			var tgt: Vector3 = a["home"] + Vector3(randf_range(-r, r), 0, randf_range(-r, r))
			if is_walkable(tgt.x, tgt.z):
				a["target"] = tgt
		var to: Vector3 = a["target"] - n.position
		to.y = 0
		var sp := 1.8 if a.get("fast", false) else 0.45
		var body := n.get_node("Body") as Node3D
		if to.length() > 0.1:
			var stepv: Vector3 = to.normalized() * minf(sp * delta, to.length())
			var nx := n.position.x + stepv.x
			var nz := n.position.z + stepv.z
			if is_walkable(nx, nz):
				n.position.x = nx
				n.position.z = nz
			n.rotation.y = lerp_angle(n.rotation.y, atan2(to.x, to.z), 0.1)
			body.position.y = abs(sin(Time.get_ticks_msec() * 0.012)) * 0.05
		else:
			body.position.y = lerpf(body.position.y, 0.0, 0.2)
		n.position.y = height_at(n.position.x, n.position.z)
