class_name Player
extends CharacterBody3D
## Qaxlok. Walks relative to the camera (stick, arrow keys or WASD), turns to face where he walks,
## and never wades into deep water (bridges and piers are fine).

const SPEED := 3.4
var world: World
var rig: CameraRig
var body: Gnome
var stick := Vector2.ZERO   # set by the on-screen joystick
var moving := false
var locked := false         # true while talking or casting
var cast_t := 0.0

func _ready() -> void:
	var cap := CapsuleShape3D.new()
	cap.radius = 0.26
	cap.height = 0.95
	var cs := CollisionShape3D.new()
	cs.shape = cap
	cs.position = Vector3(0, 0.48, 0)
	add_child(cs)
	body = Gnome.make("Qaxlok", "#2b4fb0", "#2b4fb0", "#f4f0e8", 1.05)
	add_child(body)
	body.add_staff()
	floor_snap_length = 0.4
	floor_max_angle = deg_to_rad(50)

func _physics_process(delta: float) -> void:
	var inp := Input.get_vector("move_left", "move_right", "move_forward", "move_back") + stick
	if inp.length() > 1.0:
		inp = inp.normalized()
	if locked:
		inp = Vector2.ZERO
	var fwd := Vector3(-sin(rig.yaw), 0, -cos(rig.yaw))
	var right := Vector3(cos(rig.yaw), 0, -sin(rig.yaw))
	var dir := fwd * -inp.y + right * inp.x
	moving = dir.length() > 0.08
	var v := dir * SPEED
	# stay out of deep water
	var next := global_position + v * delta * 4.0
	if moving and not world.is_walkable(next.x, next.z):
		if world.is_walkable(next.x, global_position.z):
			v.z = 0.0
		elif world.is_walkable(global_position.x, next.z):
			v.x = 0.0
		else:
			v = Vector3.ZERO
	velocity.x = v.x
	velocity.z = v.z
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= 18.0 * delta
	move_and_slide()
	if global_position.y < -3.0:
		global_position = world.spawn + Vector3(0, 1, 0)
	if moving:
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-delta * 12.0))
	body.walking = moving and v.length() > 0.1
	if cast_t > 0.0:
		cast_t -= delta

## The staff swings up while a spell is being cast.
func play_cast() -> void:
	cast_t = 0.6
	var staff := body.find_child("Staff", true, false) as Node3D
	if staff:
		var tw := create_tween()
		tw.tween_property(staff, "rotation:x", -1.2, 0.2)
		tw.tween_property(staff, "rotation:x", 0.0, 0.35)
