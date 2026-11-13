extends Interactable
class_name Openable

signal object_opened()

@export var door_controller: DoorController

@export_group("Basic Settings")
@export var is_open: bool = false
@export var open_animation: String = "open"
@export var close_animation: String = "close"

@export_group("Advanced animations")
@export var use_directional_opening: bool = false
@export var open_animation_forward: String = "open_forward"
@export var open_animation_backward: String = "open_backward"
@export var close_animation_forward: String = "close_forward"
@export var close_animation_backward: String = "close_backward"

@export_group("Animation Player Settings")
@onready var anim_player: AnimationPlayer = get_node_or_null("../AnimationPlayer")
@export var anim_player_override: AnimationPlayer = null

var player: Player

var is_playing : bool = false
var last_open_direction := ""  # "forward" or "backward

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player = players[0]
	
	# Setup animator if not manually assigned
	if anim_player_override:
		anim_player = anim_player_override
	if not anim_player:
		anim_player = get_node_or_null("AnimationPlayer")

# --- MAIN CHANGE HERE ---
func interact():
	if door_controller:
		door_controller.request_interaction(player)
		object_opened.emit() 
		return 
	
	if not anim_player:
		return
	if is_playing:
		return
	
	if use_directional_opening:
		advance_open()
	else:
		open()

func open():
	var anim_name = open_animation if not is_open else close_animation
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		is_playing = true
		is_open = !is_open # Change internal state
		object_opened.emit()

func advance_open():
	var anim_name = open_animation if not is_open else close_animation
	if player:
		var to_player = (player.global_transform.origin - global_transform.origin).normalized()
		var door_forward = $"..".global_transform.basis.z  # Door "forward" direction
		var dot = door_forward.dot(to_player)
		var dir = "forward" if dot > 0.0 else "backward"
		last_open_direction = dir
		if not is_open:
			anim_name = open_animation_forward if dir == "forward" else open_animation_backward
		else:
			anim_name = close_animation_forward if last_open_direction == "forward" else close_animation_backward
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)
		is_playing = true
	else:
		return
	is_open = !is_open
	object_opened.emit()
	
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	is_playing = false
