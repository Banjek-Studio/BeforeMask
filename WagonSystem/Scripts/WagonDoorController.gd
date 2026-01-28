extends Node
class_name DoorController

@export var openable_object: BaseOpenableObject

enum DoorState { OPEN, CLOSED, LOCKED, JAMMED }
@export var state: DoorState = DoorState.CLOSED
var is_animating: bool = false

func _ready() -> void:

	if openable_object and openable_object.animation_player:
		openable_object.animation_player.animation_finished.connect(_on_animation_finished)
	else:
		push_warning("DoorController '%s' cannot connect to AnimationPlayer!" % name)

func request_interaction(_player: Player) -> void:
	if is_animating:
		return
	if state == DoorState.LOCKED or state == DoorState.JAMMED:
		print("%s: Interaction ignored, door is %s." % [name, DoorState.keys()[state]])
		return
	
	is_animating = true
	
	# Визначаємо, яку анімацію програти
	if state == DoorState.OPEN:
		close_door()
	elif state == DoorState.CLOSED:
		unlock_and_open()

# --- ЗМІНА ---
# Тепер ці функції також викликають анімацію
func unlock_and_open() -> void:
	if state == DoorState.LOCKED or state == DoorState.CLOSED:
		_play_animation("open")
		state = DoorState.OPEN

func unlock() -> void:
	if state == DoorState.LOCKED:
		state = DoorState.CLOSED

# --- НОВА ФУНКЦІЯ ---
func close_door() -> void:
	if state == DoorState.OPEN:
		_play_animation("close")
		state = DoorState.CLOSED
	
func close_and_lock() -> void:
	if state != DoorState.LOCKED:
		_play_animation("close")
		state = DoorState.LOCKED

func close_and_jam() -> void:
	if state != DoorState.JAMMED:
		_play_animation("jammed")
		state = DoorState.JAMMED

func _play_animation(anim_name: String) -> void:
	if openable_object:
		openable_object._play_animation(anim_name)

func _on_animation_finished(_anim_name: StringName) -> void:
	is_animating = false
