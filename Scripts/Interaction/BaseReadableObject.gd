extends RigidBody3D

class_name BaseReadableObject

func _play_toggle_sound():
	$ReadSound.play()


func _on_read_area_item_read() -> void:
	_play_toggle_sound()
