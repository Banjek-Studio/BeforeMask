extends AnimatableBody3D
class_name BaseOpenableObject

@export var animation_player: AnimationPlayer

func _play_open_sound():
	$OpenSound.pitch_scale = randf_range(0.9, 1.1)
	$OpenSound.play()

func _play_animation(anim_name: String) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		# Check to not play the same animation that is already playing
		if not animation_player.is_playing() or animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
	else:
		push_warning("Animation '%s' not found on %s" % [anim_name, name])

func _on_open_sound_finished() -> void:
	pass

func _on_open_area_object_opened() -> void:
	_play_open_sound()
