extends Node

@onready var neurons : Dictionary
@onready var narratives : Dictionary

func _ready() -> void:
	#copy data from neural_general_data
	neurons = NeuralGeneralData.neurons
	narratives = NeuralGeneralData.narratives
	
	var test_contexts = [
		{"river": 1, "forest": 2, "hill": 0, "hunger": 1, "threat": -4},
		{"river": 1, "forest": 2, "hill": 0, "hunger": 1, "threat": 0},
		{"river": 1, "forest": 2, "hill": 0, "hunger": 1, "threat": 0},
		{"river": 1, "forest": 2, "hill": 0, "hunger": 1, "threat": 0},
		{"river": 1, "forest": 2, "hill": 0, "hunger": 1, "threat": 1},
	]

	for context in test_contexts:
		var message = get_narrator_message(context)
		print("Context: ", context)
		print("Narrator: ", message)
		print("---")
	
func select_neuron(context: Dictionary) -> String:
	var scores = {}

	for neuron_name in neurons.keys():
		var neuron_data = neurons[neuron_name]
		var weights = neuron_data["weights"]
		var required_inputs = neuron_data.get("required_inputs", [])
		var min_score = neuron_data.get("min_score", -INF)

		# skip neuron if any required input is missing or <= 0
		var skip = false
		for req in required_inputs:
			if context.get(req, 0) <= 0:
				skip = true
				break
		if skip:
			continue

		# calculate score
		var score = 0
		for input_name in context.keys():
			if weights.has(input_name):
				score += context[input_name] * weights[input_name]

		# skip neuron if score < min_score
		if score < min_score:
			continue

		scores[neuron_name] = score

	# convert positive scores into probabilities
	var total = 0.0
	for s in scores.values():
		total += max(s, 0)

	if total == 0:
		# if no neuron passed, pick random from all
		return neurons.keys()[randi() % neurons.size()]

	var r = randf()
	var accum = 0.0
	for k in scores.keys():
		var p = max(scores[k], 0) / total
		accum += p
		if r <= accum:
			return k

	return neurons.keys()[randi() % neurons.size()]


func get_narrator_message(context: Dictionary) -> String:
	var neuron = select_neuron(context)
	return narratives[neuron][randi() % narratives[neuron].size()]
