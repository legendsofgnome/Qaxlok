extends Node3D
## Sets up the village slice: sky and sun, the world, Qaxlok, the camera and the touch UI,
## and runs what happens when you press A (talk, Mend, open, light, pick up).

var world: World
var player: Player
var rig: CameraRig
var ui: GameUI
var target: Interactable
var talking: Interactable
var talk_lines: Array = []
var talk_i := 0
var talk_name := ""

func _ready() -> void:
	_environment()
	world = World.new()
	world.name = "World"
	add_child(world)
	player = Player.new()
	player.name = "Qaxlok"
	player.world = world
	add_child(player)
	player.global_position = world.spawn + Vector3(0, world.height_at(world.spawn.x, world.spawn.z) + 0.3, 0)
	player.rotation.y = world.spawn_r
	rig = CameraRig.new()
	add_child(rig)
	rig.target = player
	rig.yaw = world.spawn_r + PI
	rig.global_position = player.global_position + Vector3(0, 0.9, 0)
	rig.set_exclude(player)
	player.rig = rig
	ui = GameUI.new()
	add_child(ui)
	ui.player = player
	ui.rig = rig
	ui.act_pressed.connect(act)
	_refresh_quests()
	ui.toast("Qaxlok’s Village")

func _environment() -> void:
	var env := Environment.new()
	var sky := Sky.new()
	var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color("#7fb3e0")
	sm.sky_horizon_color = Color("#d8e8f0")
	sm.ground_horizon_color = Color("#d8e8f0")
	sm.ground_bottom_color = Color("#8fae7a")
	sky.sky_material = sm
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b9c8e0")
	env.ambient_light_energy = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color("#d8e6ee")
	env.fog_density = 0.008
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff2d8")
	sun.light_energy = 1.15
	sun.rotation = Vector3(deg_to_rad(-48), deg_to_rad(-35), 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)

# ---------------------------------------------------------------- every frame
func _process(delta: float) -> void:
	target = null if talking else _find_target()
	if target and rig.cam:
		var p := target.global_position + Vector3(0, 1.75 if target.kind == "npc" else 0.95, 0)
		var on := not rig.cam.is_position_behind(p)
		ui.show_marker(rig.cam.unproject_position(p), on)
	else:
		ui.show_marker(Vector2.ZERO, false)
	for it in world.npcs:
		_npc_idle(it, delta)
	for it in world.interactables:
		if it.kind == "gem" and is_instance_valid(it) and it.visual:
			it.visual.rotation.y += delta * 1.5
	if Input.is_action_just_pressed("act"):
		act()

func _find_target() -> Interactable:
	var best: Interactable = null
	var bd := 99.0
	var fwd := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	for it in world.interactables:
		if not is_instance_valid(it):
			continue
		var d := it.global_position - player.global_position
		d.y = 0.0
		var dist := d.length()
		if dist > it.reach:
			continue
		var facing := fwd.dot(d.normalized()) if dist > 0.01 else 1.0
		if dist > 0.7 and facing < 0.15:
			continue
		if dist < bd:
			bd = dist
			best = it
	return best

func _npc_idle(it: Interactable, delta: float) -> void:
	var g := it.visual as Gnome
	if g == null:
		return
	if it == talking:
		g.walking = false
		var to := player.global_position - it.global_position
		it.rotation.y = lerp_angle(it.rotation.y, atan2(to.x, to.z), 0.15)
		return
	var home: Vector3 = it.extra["home"]
	if not it.extra.has("t") or it.extra["t"] <= 0.0:
		it.extra["t"] = randf_range(2.0, 6.0)
		it.extra["goal"] = home + Vector3(randf_range(-1.6, 1.6), 0, randf_range(-1.6, 1.6))
	it.extra["t"] -= delta
	var goal: Vector3 = it.extra["goal"]
	var to2 := goal - it.position
	to2.y = 0.0
	if to2.length() > 0.08 and world.is_walkable(goal.x, goal.z):
		var step := to2.normalized() * minf(0.7 * delta, to2.length())
		it.position.x += step.x
		it.position.z += step.z
		it.rotation.y = lerp_angle(it.rotation.y, atan2(to2.x, to2.z), 0.12)
		g.walking = true
	else:
		g.walking = false
	it.position.y = world.height_at(it.position.x, it.position.z)

# ---------------------------------------------------------------- pressing A
func act() -> void:
	if talking:
		_advance_talk()
		return
	if target == null or player.locked:
		return
	var it := target
	var to := it.global_position - player.global_position
	player.rotation.y = atan2(to.x, to.z)
	match it.kind:
		"npc":
			talking = it
			talk_lines = it.extra["lines"]
			talk_i = 0
			talk_name = it.label
			player.locked = true
			(it.visual as Gnome).talking = true
			ui.say(talk_name, talk_lines[0])
			Save.add_to("talked", it.label)
		"pot":
			if it.state == 0:
				var mend_pot := func():
					it.state = 1
					it.set_visual(Props.pot(false, it.extra["barrel"]))
					Save.add_to("mended", it.id)
					_burst(it.global_position + Vector3(0, 0.4, 0), Color("#8fc8ff"))
					ui.toast("Mended! Good as new.")
				_cast(mend_pot)
			else:
				ui.toast("It’s already whole.")
		"chest":
			if it.state == 0:
				it.state = 1
				var lid := it.visual.get_node("Lid") as Node3D
				create_tween().tween_property(lid, "rotation:x", -1.9, 0.35)
				Save.add_to("chests", it.id)
				var loot: String = it.extra.get("loot", "gems")
				if loot == "gems":
					Save.data["gems"] = int(Save.data["gems"]) + 2
					ui.toast("Two shiny gems!")
				else:
					ui.toast("Inside: a %s! (It will matter in the full game.)" % loot)
				Save.save_game()
				_burst(it.global_position + Vector3(0, 0.5, 0), Color("#ffd36a"))
			else:
				ui.toast("Empty now.")
		"shrine":
			if it.state < 2:
				var work_shrine := func():
					it.state += 1
					it.set_visual(Props.shrine(it.state))
					Save.data["shrines"][it.id] = it.state
					Save.save_game()
					_burst(it.global_position + Vector3(0, 1.0, 0), Color("#ffd36a") if it.state == 2 else Color("#8fc8ff"))
					ui.toast("The shrine glows warmly." if it.state == 2 else "Shrine mended! Press A again to light it.")
				_cast(work_shrine)
			else:
				ui.toast("The shrine glows warmly.")
		"gem":
			Save.data["gems"] = int(Save.data["gems"]) + 1
			Save.add_to("picked", it.id)
			_burst(it.global_position + Vector3(0, 0.3, 0), Color("#5fd0ff"))
			ui.toast("A gem!")
			world.interactables.erase(it)
			it.queue_free()
		"herb":
			Save.data["plants"] = int(Save.data["plants"]) + 1
			Save.add_to("picked", it.id)
			ui.toast("Picked: %s" % String(it.extra["herb"]).capitalize())
			world.interactables.erase(it)
			it.queue_free()
	_refresh_quests()

func _advance_talk() -> void:
	talk_i += 1
	if talk_i >= talk_lines.size():
		ui.hide_dialogue()
		(talking.visual as Gnome).talking = false
		talking = null
		player.locked = false
		_refresh_quests()
	else:
		ui.say(talk_name, talk_lines[talk_i])

## Raise the staff, then the spell lands.
func _cast(effect: Callable) -> void:
	player.locked = true
	player.play_cast()
	await get_tree().create_timer(0.45).timeout
	effect.call()
	player.locked = false
	_refresh_quests()

func _burst(pos: Vector3, c: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 28
	p.lifetime = 0.9
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, -2.5, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	var m := SphereMesh.new()
	m.radius = 0.05
	m.height = 0.1
	m.radial_segments = 6
	m.rings = 3
	p.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = c
	p.material_override = mat
	add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)

func _refresh_quests() -> void:
	var pots := 0
	var pots_ok := 0
	var chests := 0
	var chests_open := 0
	var lit := false
	for it in world.interactables:
		if not is_instance_valid(it):
			continue
		match it.kind:
			"pot":
				pots += 1
				if it.state == 1:
					pots_ok += 1
			"chest":
				chests += 1
				if it.state == 1:
					chests_open += 1
			"shrine":
				if it.state == 2:
					lit = true
	var npcs := world.npcs.size()
	var talked: int = Save.data["talked"].size()
	ui.set_quests([
		["Mend the broken pots and barrels (%d/%d)" % [pots_ok, pots], pots_ok == pots],
		["Mend and light a wizard shrine", lit],
		["Open the chests (%d/%d)" % [chests_open, chests], chests_open == chests],
		["Say hello to everyone (%d/%d)" % [mini(talked, npcs), npcs], talked >= npcs],
	], int(Save.data["gems"]), int(Save.data["plants"]))
