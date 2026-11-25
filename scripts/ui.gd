class_name GameUI
extends CanvasLayer
## Touch controls and on-screen text: a joystick on the left, drag on the right to look around,
## pinch to zoom, the big A button, the dialogue scroll, toasts and the quest list.

signal act_pressed

var player: Player
var rig: CameraRig
var _root: Control
var _joy: Control
var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_vec := Vector2.ZERO
var _cam_touches := {}
var _a_btn: Button
var _dlg: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _toast: Label
var _toast_t := 0.0
var _quests: Label
var _marker: Label

const PARCH := Color("#f3e2b8")
const INK := Color("#3b2513")
const NAVY := Color("#2c4a86")
const GOLD := Color("#f6d77a")

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_joy = Control.new()
	_joy.set_anchors_preset(Control.PRESET_FULL_RECT)
	_joy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joy.draw.connect(_draw_joy)
	_root.add_child(_joy)
	# quest list
	_quests = Label.new()
	_quests.position = Vector2(16, 16)
	_quests.add_theme_color_override("font_color", INK)
	_quests.add_theme_font_size_override("font_size", 20)
	var qbg := PanelContainer.new()
	qbg.add_theme_stylebox_override("panel", _box(Color(PARCH, 0.92), 14))
	qbg.position = Vector2(12, 12)
	qbg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	qbg.add_child(_quests)
	_root.add_child(qbg)
	# the A button
	_a_btn = Button.new()
	_a_btn.text = "A"
	_a_btn.add_theme_font_size_override("font_size", 48)
	_a_btn.add_theme_color_override("font_color", NAVY)
	_a_btn.add_theme_color_override("font_pressed_color", NAVY)
	_a_btn.add_theme_color_override("font_hover_color", NAVY)
	for st in ["normal", "hover", "pressed", "focus"]:
		_a_btn.add_theme_stylebox_override(st, _box(GOLD if st != "pressed" else GOLD.darkened(0.15), 70, Color("#b8892e")))
	_a_btn.custom_minimum_size = Vector2(128, 128)
	_anchor(_a_btn, Vector2(1, 1), Rect2(-168, -168, 136, 136))
	_a_btn.focus_mode = Control.FOCUS_NONE
	_a_btn.pressed.connect(func(): act_pressed.emit())
	_root.add_child(_a_btn)
	# dialogue scroll
	_dlg = PanelContainer.new()
	_dlg.add_theme_stylebox_override("panel", _box(PARCH, 10, Color("#7a4a22")))
	_anchor(_dlg, Vector2(0.5, 1), Rect2(-330, -340, 660, 140))
	_dlg.visible = false
	_dlg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dlg.gui_input.connect(_on_dlg_input)
	var vb := VBoxContainer.new()
	_dlg.add_child(vb)
	_dlg_name = Label.new()
	_dlg_name.add_theme_color_override("font_color", INK)
	_dlg_name.add_theme_font_size_override("font_size", 24)
	_dlg_text = Label.new()
	_dlg_text.add_theme_color_override("font_color", INK)
	_dlg_text.add_theme_font_size_override("font_size", 22)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(600, 0)
	vb.add_child(_dlg_name)
	vb.add_child(_dlg_text)
	_root.add_child(_dlg)
	# toast
	_toast = Label.new()
	_anchor(_toast, Vector2(0.5, 0), Rect2(-300, 24, 600, 48))
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 24)
	_toast.add_theme_color_override("font_color", INK)
	_toast.add_theme_stylebox_override("normal", _box(PARCH, 18))
	_toast.modulate.a = 0.0
	_root.add_child(_toast)
	# the floating "A" above whatever can be used
	_marker = Label.new()
	_marker.text = "A"
	_marker.add_theme_font_size_override("font_size", 22)
	_marker.add_theme_color_override("font_color", NAVY)
	_marker.add_theme_stylebox_override("normal", _box(Color.WHITE, 16))
	_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_marker.custom_minimum_size = Vector2(34, 34)
	_marker.visible = false
	_root.add_child(_marker)

## Pin a control to a point on the screen (0..1 on each axis), with its rect relative to that point.
func _anchor(c: Control, at: Vector2, r: Rect2) -> void:
	c.anchor_left = at.x
	c.anchor_right = at.x
	c.anchor_top = at.y
	c.anchor_bottom = at.y
	c.offset_left = r.position.x
	c.offset_top = r.position.y
	c.offset_right = r.position.x + r.size.x
	c.offset_bottom = r.position.y + r.size.y

func _on_dlg_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
		act_pressed.emit()

func _box(c: Color, radius: int, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(4)
	return sb

# ---------------------------------------------------------------- touch
func _unhandled_input(event: InputEvent) -> void:
	var vw := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			if e.position.x < vw.x * 0.42 and _joy_index == -1:
				_joy_index = e.index
				_joy_center = e.position
				_joy_vec = Vector2.ZERO
			else:
				_cam_touches[e.index] = e.position
		else:
			if e.index == _joy_index:
				_joy_index = -1
				_joy_vec = Vector2.ZERO
			_cam_touches.erase(e.index)
		_joy.queue_redraw()
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_index:
			_joy_vec = ((d.position - _joy_center) / 70.0).limit_length(1.0)
			_joy.queue_redraw()
		elif _cam_touches.has(d.index):
			if _cam_touches.size() >= 2:
				var keys := _cam_touches.keys()
				var other: Vector2 = _cam_touches[keys[0] if keys[0] != d.index else keys[1]]
				var before: float = (_cam_touches[d.index] as Vector2).distance_to(other)
				var after: float = d.position.distance_to(other)
				if before > 1.0 and after > 1.0:
					rig.zoom(before / after)
			else:
				rig.drag(d.relative)
			_cam_touches[d.index] = d.position
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			rig.zoom(0.9)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			rig.zoom(1.1)

func _draw_joy() -> void:
	if _joy_index == -1:
		return
	_joy.draw_circle(_joy_center, 72, Color(1, 1, 1, 0.18))
	_joy.draw_arc(_joy_center, 72, 0, TAU, 48, Color(1, 1, 1, 0.5), 3.0)
	_joy.draw_circle(_joy_center + _joy_vec * 60.0, 30, Color(1, 1, 1, 0.55))

func _process(delta: float) -> void:
	if player:
		player.stick = _joy_vec
	if _toast_t > 0.0:
		_toast_t -= delta
		_toast.modulate.a = clampf(_toast_t * 2.0, 0.0, 1.0)

# ---------------------------------------------------------------- text
func say(who: String, text: String) -> void:
	_dlg.visible = true
	_dlg_name.text = who
	_dlg_text.text = text

func hide_dialogue() -> void:
	_dlg.visible = false

func toast(text: String) -> void:
	_toast.text = text
	_toast_t = 2.6
	_toast.modulate.a = 1.0

func set_quests(lines: Array, gems: int, plants: int) -> void:
	var s := "◆ %d    ✿ %d\n" % [gems, plants]
	for l in lines:
		s += ("✓ " if l[1] else "• ") + str(l[0]) + "\n"
	_quests.text = s.strip_edges()

func show_marker(screen_pos: Vector2, on: bool) -> void:
	_marker.visible = on
	if on:
		_marker.position = screen_pos - Vector2(17, 17)
