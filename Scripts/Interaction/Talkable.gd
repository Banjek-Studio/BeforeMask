extends Interactable
class_name Talkable

@export var dialogue: DialogueData
signal object_talked()

func interact() -> void:
	var dialogue_system = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue_system:
		dialogue_system.start_dialogue(dialogue)
		emit_signal("object_talked")
	else:
		print("Talked to %s, but no DialogueSystem found in scene." % name)

# Optional helper - in case animations trigger dialogue advance
func on_animation_finished() -> void:
	var dialogue_system = get_tree().get_first_node_in_group("DialogueSystem")
	if dialogue_system and dialogue_system.is_dialogue_running():
		dialogue_system.advance_dialogue()
