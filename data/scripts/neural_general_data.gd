extends Node

var neurons : Dictionary = {
	"ambush": {
		"weights": {"river": 0, "forest": 1.3, "hill": 0, "threat": 2},
		"required_inputs": ["threat"]
	},
	"find_log": {
		"weights": {"river": 2.1, "forest": 0, "hill": 0, "threat": -1},
	},
	"peaceful_travel": {
		"weights": {"river": 0, "forest": 2, "hill": 1, "hunger": -1.5, "threat": -2},
	}
}

# narrator messages for each event
var narratives : Dictionary = {
	"find_log": [
		"A fallen log spans the river. You could try to cross.",
		"You see a sturdy log nearby, partially submerged."
	],
	"ambush": [
		"Suddenly, predators emerge from the bushes!",
		"A group of hostile creatures blocks your path."
	],
	"peaceful_travel": [
		"The path is quiet, the swarm moves without incident.",
		"You pass through the area with no trouble."
	]
}
