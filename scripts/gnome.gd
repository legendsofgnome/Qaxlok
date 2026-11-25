class_name Gnome
extends Node3D
## A gnome body: placeholder shapes for now (robe, head, beard, pointed hat, little feet).
## If res://art/<name>.glb exists (e.g. exported from Nomad Sculpt), that model is used instead.
## Walking makes the body bob and the feet step; set `walking` each frame.

var walking := false
var talking := false
var _t := 0.0
var _body: Node3D
var _feet: Array[Node3D] = []
var _model: Node3D

static func make(gname: String, robe: String, hat: String, beard: String = "#f4f0e8", height_scale := 1.0) -> Gnome:
	var g := Gnome.new()
	g.name = gname
	g._build(gname, robe, hat, beard, height_scale)
	return g

func _build(gname: String, robe: String, hat: String, beard: String, hs: float) -> void:
	_body = Node3D.new()
	add_child(_body)
	var art := "res://art/%s.glb" % gname.to_lower().replace(" ", "_")
	if ResourceLoader.exists(art):
		_model = (load(art) as PackedScene).instantiate()
		Toon.apply_to_model(_model)
		_body.add_child(_model)
	else:
		Props.mi(_body, Props.cyl(0.16, 0.27, 0.52, 18), robe, Vector3(0, 0.3, 0))
		Props.mi(_body, Props.sph(0.15, 0.3, 16), "#f2c8a0", Vector3(0, 0.66, 0))
		Props.mi(_body, Props.sph(0.045), "#e8a888", Vector3(0, 0.64, 0.15))
		for s in [-1.0, 1.0]:
			Props.mi(_body, Props.sph(0.022), "#1a1416", Vector3(s * 0.055, 0.7, 0.13), Vector3.ZERO, false)
		var b := Props.mi(_body, Props.cyl(0.0, 0.15, 0.3, 12), beard, Vector3(0, 0.5, 0.1))
		b.rotation = Vector3(PI, 0, 0)
		Props.mi(_body, Props.cyl(0.0, 0.2, 0.56, 18), hat, Vector3(0, 0.98, -0.02), Vector3(-0.12, 0, 0))
		Props.mi(_body, Props.cyl(0.2, 0.2, 0.03, 18), hat, Vector3(0, 0.71, 0), Vector3.ZERO, false)
	for s in [-1.0, 1.0]:
		var f := Node3D.new()
		f.position = Vector3(s * 0.09, 0.05, 0)
		add_child(f)
		Props.mi(f, Props.sph(0.06, 0.07, 10), "#4a3426", Vector3(0, 0, 0.03))
		_feet.append(f)
	scale = Vector3.ONE * hs

func _process(delta: float) -> void:
	_t += delta
	var step := 10.0
	if walking:
		_body.position.y = abs(sin(_t * step)) * 0.035
		_body.rotation.z = sin(_t * step) * 0.04
		_feet[0].position.z = sin(_t * step) * 0.08
		_feet[1].position.z = -sin(_t * step) * 0.08
	else:
		_body.position.y = lerpf(_body.position.y, sin(_t * 2.0) * 0.006, 0.2)
		_body.rotation.z = lerpf(_body.rotation.z, 0.0, 0.2)
		_feet[0].position.z = lerpf(_feet[0].position.z, 0.0, 0.2)
		_feet[1].position.z = lerpf(_feet[1].position.z, 0.0, 0.2)
	if talking:
		_body.rotation.x = sin(_t * 12.0) * 0.02
	else:
		_body.rotation.x = 0.0

## A little staff for Qaxlok; the crystal glows in the colour of the socketed gem.
func add_staff(gem_color: String = "#7fd0ff") -> Node3D:
	var st := Node3D.new()
	st.name = "Staff"
	st.position = Vector3(0.24, 0.32, 0.06)
	_body.add_child(st)
	Props.mi(st, Props.cyl(0.018, 0.022, 0.9, 8), "#8a6440", Vector3(0, 0.25, 0))
	Props.mi(st, Props.sph(0.06), gem_color, Vector3(0, 0.74, 0), Vector3.ZERO, true, 0.9)
	return st
