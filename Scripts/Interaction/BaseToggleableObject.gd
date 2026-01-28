extends StaticBody3D

class_name BaseToggleableObject

func _play_toggle_sound():
	$ToggleSound.play()

func _on_toggle_area_object_toggled() -> void:
	_play_toggle_sound()
