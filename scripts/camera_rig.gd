class_name CameraRig
extends Node3D
## Third-person camera: follows behind and a little above Qaxlok, swings round behind him as he walks,
## can be dragged to look around (right side of the screen), pinched or scrolled to zoom.

var target: Node3D
var yaw := 0.0
var pitch := 0.42
var dist := 5.2
var _manual := 0.0          # seconds since the player last dragged the camera
var _arm: SpringArm3D
var cam: Camera3D

func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.spring_length = dist
	_arm.margin = 0.2
	add_child(_arm)
	var s := SphereShape3D.new()
	s.radius = 0.25
	_arm.shape = s
	cam = Camera3D.new()
	cam.fov = 55.0
	cam.near = 0.1
	cam.far = 300.0
	_arm.add_child(cam)
	cam.current = true

func set_exclude(body: CollisionObject3D) -> void:
	_arm.add_excluded_object(body.get_rid())

func drag(rel: Vector2) -> void:
	yaw -= rel.x * 0.008
	pitch = clampf(pitch + rel.y * 0.006, 0.08, 1.25)
	_manual = 0.0

func zoom(f: float) -> void:
	dist = clampf(dist * f, 2.4, 12.0)

func _process(delta: float) -> void:
	if target == null:
		return
	_manual += delta
	if Input.is_action_pressed("cam_left"):
		yaw += delta * 1.8
		_manual = 0.0
	if Input.is_action_pressed("cam_right"):
		yaw -= delta * 1.8
		_manual = 0.0
	var moving: bool = target.get("moving") == true
	if moving and _manual > 1.2:
		# swing round behind Qaxlok
		var behind: float = target.rotation.y + PI
		yaw = lerp_angle(yaw, behind, 1.0 - exp(-delta * 2.2))
	position = position.lerp(target.global_position + Vector3(0, 0.9, 0), 1.0 - exp(-delta * 10.0))
	rotation = Vector3(-pitch, yaw, 0)
	_arm.spring_length = lerpf(_arm.spring_length, dist, 0.2)
