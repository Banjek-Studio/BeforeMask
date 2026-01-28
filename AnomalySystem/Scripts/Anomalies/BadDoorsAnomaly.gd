extends BaseAnomalyObject
class_name BadDoorsAnomaly

var door_controllers: Array[DoorController] = []

func initialize(wagon: Wagon):
	super.initialize(wagon)
	# Знаходимо всі двері в батьківському вагоні
	door_controllers.append(parent_wagon.entry_door)
	door_controllers.append(parent_wagon.exit_door)
	door_controllers.append(parent_wagon.entry_tambour_door)
	door_controllers.append(parent_wagon.exit_tambour_door)

func activate():
	super.activate()
	# Запускаємо цикл, який буде випадково смикати двері
	_start_door_flicker_loop()

func deactivate():
	super.deactivate()
	# Тут логіка зупинки циклу, якщо він ще активний

func _start_door_flicker_loop():
	# Ця функція буде викликати сама себе, поки аномалія активна
	while is_active:
		# Чекаємо випадковий час
		await get_tree().create_timer(randf_range(1.0, 4.0)).timeout
		
		# Якщо гравець вийшов з вагона (аномалія стала неактивною), зупиняємось
		if not is_active: break
		
		# Вибираємо випадкові двері
		var random_door = door_controllers.pick_random()
		if random_door and random_door.state == DoorController.DoorState.CLOSED:
			# Якщо двері зачинені, коротко відчиняємо і зачиняємо їх
			random_door.unlock_and_open()
			await get_tree().create_timer(0.5).timeout
			if is_active: # Перевіряємо знову
				random_door.close_door()
