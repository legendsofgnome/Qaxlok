class_name Dialogue
## What the villagers say (carried over from the prototype).

const LINES := {
	"Chipper": ["Qaxlok! Sunpetal and a beetle make a lively draught. Try them in a cauldron.", "Old wizard shrines still stand around the village. Mend one, then light it.", "I heard something hiccup in the woods last night. Odd."],
	"Gerry": ["My old gate fell apart long ago. Stand close and press A. A wizard can mend it with a spell."],
	"Tim": ["The bridge is whole again and I can cross without falling in! Mostly.", "Dewbell and mintleaf make a calming tea, by the way."],
	"Dingleberry": ["Qaxlok! Do you like my hat? I grew every flower on it myself.", "Rosepuff and sunpetal are my favourites. Gently, with the sickle."],
	"Poky": ["Hello hello! Careful, my hat sometimes pokes the clouds.", "Cut herbs with the sickle, not your boots."],
	"Saffron": ["A wizard! Delightful. There is a tower just up the path with a weather-vane. The wind used to answer it.", "Its door is rubble now. A mender might fix that."],
	"Orla": ["Apples fall all day here and grow back by supper. Take what you like.", "If a cauldron is nearby, an apple and some mintleaf make a lovely cider."],
	"Millie": ["My pot cart tipped over and everything cracked. Could you Mend the pieces?", "Walk up and press A beside each broken one."],
	"Hecubah": ["My hammer keeps breaking my pots. Mend them, would you?", "Poofy’s been restless lately. Strange sparkles keep drifting from the east."],
	"Chugglass": ["Zzzz… one more cider… zzz…", "(He is fast asleep, smiling.)"],
	"Jaronemo": ["Did you see me up there? I was SO high.", "Next I’m climbing the tower. From the outside!"],
	"Dilbordt": ["Oh thank goodness, a wizard! I keep getting stuck in things.", "Today it was a barrel. Yesterday, a hat."],
	"Boomer": ["Welcome to the armory! Mind the scorch marks.", "Black powder is perfectly safe. Mostly. Sometimes."],
	"Lyphtacus": ["We built every house in this village. Well, most of the walls."],
	"Poolicas": ["Lyphtacus measures, I hammer. Sometimes the other way round.", "Mind the ladder, it wobbles."],
}

static func lines(who: String) -> Array:
	return LINES.get(who, ["Hello there, Qaxlok!"])
