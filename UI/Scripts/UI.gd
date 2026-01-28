extends Control
class_name UI

signal line_finished()
signal choice_selected(index)
signal item_closed()

@export var default_text_speed: float = 0.03
@export var auto_advance_delay: float = 1.0

@onready var item_placeholder = $BoxContainer/ItemPlaceholder
@onready var item_texture = $BoxContainer/ItemPlaceholder/ItemTexture
@onready var text_label: RichTextLabel = $BoxContainer/DialoguePlaceholder/DialogueContainer/MarginContainer/BoxContainer/TextEdit
@onready var speaker_label: Label = $BoxContainer/DialoguePlaceholder/DialogueContainer/MarginContainer/BoxContainer/Label
@onready var choices_container: BoxContainer = $BoxContainer/DialoguePlaceholder/DialogueContainer/ButtonMargin/AspectRatioContainer/ButtonsContainer
@onready var continue_indicator: Control = $BoxContainer/DialoguePlaceholder/DialogueContainer/ContinueIndicator if has_node("BoxContainer/DialoguePlaceholder/DialogueContainer/ContinueIndicator") else null
@onready var portrait_texture: TextureRect = $BoxContainer/DialoguePlaceholder/DialogueContainer/PortraitTexture if has_node("BoxContainer/DialoguePlaceholder/DialogueContainer/PortraitTexture") else null

var is_typing := false
var skip_typing := false
var auto_advance_timer: SceneTreeTimer
var _line_done := false

func _ready() -> void:
	add_to_group("UI")
	hide_all()
	visible = false

func hide_all() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	item_closed.emit()
	item_texture.visible = false
	visible = true
	if text_label:
		text_label.text = ""
	if speaker_label:
		speaker_label.text = ""
	if continue_indicator:
		continue_indicator.visible = false
	if choices_container:
		choices_container.visible = false
	if portrait_texture:
		portrait_texture.visible = false

func show_item(texture: Texture2D):
	visible = true	
	item_texture.texture = texture
	item_texture.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called by DialogueSystem to display a dialogue line
func present_line(line: DialogueLine, _is_last_line: bool = false) -> void:
	if not text_label:
		push_error("DialogueUI missing text_label reference.")
		return

	hide_all()
	_line_done = false
	is_typing = true
	skip_typing = false

	if speaker_label:
		speaker_label.text = line.speaker_name
	if portrait_texture and line.speaker_emotion != null:
		portrait_texture.visible = true

	var speed := line.text_speed if line.text_speed > 0 else default_text_speed

	# play audio if present
	if line.audio_clip:
		var player := AudioStreamPlayer.new()
		add_child(player)
		player.stream = line.audio_clip
		player.play()
		player.connect("finished", player.queue_free)

	# Typewriter effect
	for i in line.text.length():
		if skip_typing:
			text_label.text = line.text
			break
		text_label.text += line.text[i]
		await get_tree().create_timer(speed).timeout

	is_typing = false
	if continue_indicator:
		continue_indicator.visible = true

	_line_done = true
	emit_signal("line_finished")

	# handle auto-advance
	if line.auto_advance:
		auto_advance_timer = get_tree().create_timer(line.wait_time if line.wait_time > 0 else auto_advance_delay)
		await auto_advance_timer.timeout
	else:
		await _wait_for_user_input()

	if continue_indicator:
		continue_indicator.visible = false
	hide_choices()

func _wait_for_user_input() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_accept"):
			break

func force_advance() -> void:
	# Called by DialogueSystem.advance_dialogue
	if is_typing:
		skip_typing = true
	elif _line_done:
		_line_done = false

func present_choices(choices: Array) -> int:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not choices_container:
		push_error("DialogueUI missing choices_container reference.")
		return -1

	choices_container.visible = true
	for i in range(choices.size()):
		var c = choices[i]
		var b := Button.new()
		b.text = c.choice_text
		b.connect("pressed", Callable(self, "_on_choice_pressed").bind(i))
		choices_container.add_child(b)

	var index := await _wait_for_choice()
	hide_choices()
	return index

func _on_choice_pressed(index: int) -> void:
	emit_signal("choice_selected", index)

func _wait_for_choice() -> int:
	var result : int = await self.choice_selected
	return result

func hide_choices() -> void:
	if choices_container:
		for c in choices_container.get_children():
			c.queue_free()
		choices_container.visible = false

func hide_dialogue() -> void:
	hide_all()
	visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel") and visible:
		hide_all()
		visible = false
