extends Node
## Autoload "Save": the input map and a small save file (user://save.json).

const PATH := "user://save.json"
var data := {}

func _ready() -> void:
	_setup_input()
	load_game()

func _setup_input() -> void:
	var keys := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"act": [KEY_SPACE, KEY_ENTER],
		"cam_left": [KEY_Q],
		"cam_right": [KEY_E],
	}
	for action in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in keys[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)

func load_game() -> void:
	data = {"mended": [], "chests": [], "shrines": {}, "picked": [], "talked": [], "gems": 0, "plants": 0}
	if FileAccess.file_exists(PATH):
		var f := FileAccess.open(PATH, FileAccess.READ)
		var parsed = JSON.parse_string(f.get_as_text())
		if parsed is Dictionary:
			for k in parsed:
				data[k] = parsed[k]

func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func has_in(list_name: String, id) -> bool:
	return str(id) in data[list_name].map(func(v): return str(v))

func add_to(list_name: String, id) -> void:
	if not has_in(list_name, id):
		data[list_name].append(str(id))
		save_game()

func reset() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	load_game()
