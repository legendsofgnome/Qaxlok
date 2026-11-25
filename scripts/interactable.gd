class_name Interactable
extends Node3D
## Anything Qaxlok can press A on: villagers, broken pots and barrels, chests, shrines, gems and herbs.

var kind := ""          # "npc", "pot", "chest", "shrine", "gem", "herb"
var id := ""            # stable id used by the save file
var label := ""         # name shown above villagers
var state := 0          # pot: 0 broken / 1 mended; chest: 0 closed / 1 open; shrine: 0 ruined / 1 mended / 2 lit
var reach := 1.7        # how close Qaxlok must be
var extra := {}         # anything else (lines for a villager, loot for a chest, herb type…)
var visual: Node3D

func set_visual(v: Node3D) -> void:
	if visual:
		visual.queue_free()
	visual = v
	add_child(v)
