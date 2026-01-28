extends Resource
class_name DialogueData

@export var dialogue_lines: Array[DialogueLine] = []
@export var choices: Array[DialogueChoice] = []

func get_line(index: int) -> DialogueLine:
	if index >= 0 and index < dialogue_lines.size():
		return dialogue_lines[index]
	return null

func has_choices() -> bool:
	return choices.size() > 0

func get_choices() -> Array[DialogueChoice]:
	return choices.duplicate()
