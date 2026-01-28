extends BaseAnomalyObject
class_name TurboWagonAnomaly

## Мінімальна швидкість, яку має підтримувати гравець.
@export var required_speed: float = 4.0
## Сила, з якою гравця відкидає назад.
@export var pushback_force: float = 2

var player_ref: CharacterBody3D

func activate():
	super.activate()
	player_ref = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	print("The train is accelerating uncontrollably! RUN!")
	# Тут можна додати ефект швидкого руху пейзажу за вікном

func _physics_process(delta):
	if not is_active or not is_instance_valid(player_ref):
		return
	
	# Перевіряємо швидкість гравця тільки по горизонталі
	var horizontal_velocity = player_ref.velocity * Vector3(1, 0, 1)
	
	if horizontal_velocity.length() < required_speed:
		# Визначаємо напрямок назад по вагону
		var push_direction = -parent_wagon.global_transform.basis.x
		player_ref.velocity += push_direction * pushback_force * delta
		# Тут можна додати логіку смерті, якщо гравця відкинуло до стіни
