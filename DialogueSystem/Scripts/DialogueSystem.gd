extends Node
class_name DialogueSystem

signal dialogue_began(dialogue_data)
signal dialogue_ended()
signal line_displayed(line_data)
signal choice_made(choice_index)
#signal dialogue_event_triggered(event_name)

@export var text_display_speed: float = 0.03
@export var auto_advance_delay: float = 1.5

var current_dialogue: DialogueData = null
var current_line_index: int = 0
var is_dialogue_active: bool = false

# Reference to UI node (optional). We'll try to find it in the scene tree.
@onready var ui = get_tree().get_first_node_in_group("UI")

# --- Public API ---
func start_dialogue(dialogue: DialogueData) -> void:
	if not dialogue:
		push_warning("DialogueSystem.start_dialogue called with null dialogue")
		return
	# If another dialogue is running, end it first
	if is_dialogue_active:
		end_dialogue()
	current_dialogue = dialogue
	current_line_index = 0
	is_dialogue_active = true
	emit_signal("dialogue_began", current_dialogue)
	# Start showing the first line
	call_deferred("display_current_line")

func display_current_line() -> void:
	if not is_dialogue_active or current_dialogue == null:
		return
	var line: DialogueLine = current_dialogue.get_line(current_line_index)
	if not line:
		# No more lines -> check choices or end
		_check_choices_or_advance()
		return
	# Notify listeners
	emit_signal("line_displayed", line)
	# If there's a UI, ask it to present the line and wait for it to finish (it will handle typing, skipping, choices)
	if ui and ui.has_method("present_line"):
		# present_line is implemented as an async function that returns when user advances or auto-advances
		await ui.present_line(line, current_dialogue.has_choices() and current_line_index == current_dialogue.dialogue_lines.size() - 1)
		# Wait for the UI to finish presenting (it will emit "line_advanced" signal internally and return)
	else:
		# Fallback: print to console and wait for a short delay
		print("%s: %s" % [line.speaker_name, line.text])
		await get_tree().create_timer(auto_advance_delay).timeout
	# After the UI indicates we're ready, move on
	_check_choices_or_advance()

func _check_choices_or_advance() -> void:
	# If the dialogue data contains choices, and we're at the end of lines, present them
	if current_dialogue and current_dialogue.has_choices() and current_line_index >= current_dialogue.dialogue_lines.size() - 1:
		# Let UI handle the choice presentation; if no UI, end dialogue
		if ui and ui.has_method("present_choices"):
			var choices = current_dialogue.get_choices()
			var picked_index = await ui.present_choices(choices)
			emit_signal("choice_made", picked_index)
			# Advance to the selected next_dialogue if provided
			if choices.size() > picked_index and choices[picked_index].next_dialogue:
				start_dialogue(choices[picked_index].next_dialogue)
			else:
				end_dialogue()
		else:
			end_dialogue()
	else:
		# Advance to next line
		current_line_index += 1
		# If we've passed the last line, end dialogue
		if current_dialogue and current_line_index >= current_dialogue.dialogue_lines.size():
			end_dialogue()
		else:
			display_current_line()

func advance_dialogue() -> void:
	# External API used to force-skip typewriting or move forward.
	# We delegate skipping/advancing behavior to UI if present.
	if ui and ui.has_method("force_advance"):
		ui.force_advance()
	else:
		# If no UI, simply move forward
		_check_choices_or_advance()

func end_dialogue() -> void:
	if not is_dialogue_active:
		return
	is_dialogue_active = false
	current_dialogue = null
	current_line_index = 0
	emit_signal("dialogue_ended")
	# Tell UI to hide
	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue()
