extends Interactable
class_name Toggleable

signal object_toggled()

@export var is_on: bool = false
@export var light_node_path: NodePath
@export var toggle_on_animation: String = "toggle_on"
@export var toggle_off_animation: String = "toggle_off"

@onready var light_node: Node = get_node_or_null(light_node_path)
@onready var anim_player: AnimationPlayer = get_node_or_null("../AnimationPlayer")

var is_playing : bool = false

func interact():
	if not anim_player:
		push_warning("Toggleable '%s' has no AnimationPlayer" % name)
		return
	var anim_name = toggle_on_animation if not is_on else toggle_off_animation
	if anim_player.has_animation(anim_name) and !is_playing:
		anim_player.play(anim_name)
		is_playing = true
	else :
		return
	is_on = !is_on
	object_toggled.emit()
	if light_node and light_node.has_method("set_visible"):
		light_node.visible = is_on
	print("Toggled %s: %s" % [name, is_on])


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	is_playing = false
