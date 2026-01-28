extends Interactable
class_name Readable

signal item_read()

@export var read_up_animation: String = "read_up"
@export var read_down_animation: String = "read_down"
@export var item_texture: Texture2D
@export var to_move: NodePath = ".."
@export_multiline var text_content: String

@onready var anim_player: AnimationPlayer = get_node_or_null("../AnimationPlayer")
@onready var move_target: RigidBody3D = get_node_or_null(to_move)
var camera: Camera3D = null

@export var is_read: bool = false
var is_playing: bool = false
var original_transform: Transform3D

func interact() -> void:
	var ui = get_tree().get_first_node_in_group("UI")
	if ui and ui.has_method("show_item"):
		if move_target:
			original_transform = move_target.global_transform
		#ui.show_item(item_texture)
		if not ui.item_closed.is_connected(_on_ui_canceled):
			ui.item_closed.connect(_on_ui_canceled)
	else:
		print("Read note: %s" % text_content)
		
	move_to_reading_position()
	play_interaction_animation()
	
	is_read = !is_read
	item_read.emit()

func move_to_reading_position() -> void:
	move_target.freeze = true
	var camera_pos = camera.global_transform.origin
	var object_pos = move_target.global_transform.origin
	
	# Calculate direction from object to camera
	var direction_to_camera = (camera_pos - object_pos).normalized()
	
	# Move object closer to camera (e.g., 70% of the way)
	var move_distance = object_pos.distance_to(camera_pos) * 0.7
	var target_position = object_pos + (direction_to_camera * move_distance)
	
	# Create a basis that looks at camera but rotated 90 degrees
	var look_transform = Transform3D().looking_at(direction_to_camera, Vector3.UP)
	var rotation_offset = Transform3D().rotated(Vector3.LEFT, deg_to_rad(90))
	var target_basis = look_transform.basis * rotation_offset.basis
	
	# Create final transform with NEW position and rotated basis
	var target_transform = Transform3D(target_basis, target_position)
	
	# Animate both movement and rotation
	var tween = create_tween()
	tween.tween_property(move_target, "global_transform", target_transform, 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(_on_tween_finished_show_ui)

func _on_tween_finished_show_ui() -> void:
	var ui = get_tree().get_first_node_in_group("UI")
	if ui and ui.has_method("show_item"):
		ui.show_item(item_texture)

func play_interaction_animation() -> void:
	if not anim_player:
		push_warning("Openable '%s' has no AnimationPlayer" % name)
		return
	
	var anim_name = read_up_animation if not is_read else read_down_animation
	if anim_player.has_animation(anim_name) and !is_playing:
		anim_player.play(anim_name)
		is_playing = true

func _on_ui_canceled() -> void:
	# Revert to original position when UI is canceled
	move_target.freeze = false
	var tween = create_tween()
	tween.tween_property(move_target, "global_transform", original_transform, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Also play the close animation if needed
	play_interaction_animation()
	
	# Disconnect the signal to avoid multiple connections
	var ui = get_tree().get_first_node_in_group("UI")
	if ui and ui.item_closed.is_connected(_on_ui_canceled):
		ui.item_closed.disconnect(_on_ui_canceled)

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		camera = get_tree().get_first_node_in_group("Camera")
	else:
		print("No player in group yet")
	
		original_transform = move_target.global_transform

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	is_playing = false
