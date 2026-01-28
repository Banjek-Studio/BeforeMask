extends RayCast3D

func _input(event):
	if event.is_action_pressed("interact") and is_colliding():
		var hit_object = get_collider()
		if hit_object and hit_object.is_in_group("Interactable"):
			if hit_object.has_method("interact"):
				hit_object.interact()
			elif hit_object.get_parent() and hit_object.get_parent().has_method("interact"):
				hit_object.get_parent().interact()
			else:
				print("Interactable object found but no interact method available")
