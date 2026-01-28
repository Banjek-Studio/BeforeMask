extends Resource
class_name DialogueChoice

@export var choice_text: String = ""
@export var next_dialogue: DialogueData
@export var requirements: Array[String] = []  # Conditions that must be met
@export var effects: Array[String] = []  # Effects when chosen

func _init(p_choice_text: String = "", p_next_dialogue: DialogueData = null):
	choice_text = p_choice_text
	next_dialogue = p_next_dialogue
