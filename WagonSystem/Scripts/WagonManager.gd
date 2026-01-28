extends Node3D
class_name WagonManager

signal score_updated(new_score: int)
signal game_won

@export_group("Core References")
@export var start_connector: WagonConnector 
@export var player: CharacterBody3D

@export_group("Scene Prefabs")
@export var wagon_scene: PackedScene
@export var connector_scene: PackedScene 

@export_group("Generation Data")
@export var initial_wagon_pool: WagonPool # Пул для звичайних вагонів
@export var first_anomaly_wagon: WagonData # Вагон, що гарантовано з'явиться першим
@export var demo_vagons: Array[Wagon]
@export var reserved_wagons: Dictionary = {}

@export_group("Game Rules")
@export var wagons_to_spawn: int = 4 # Кількість активних вагонів у світі
@export var score_to_win: int = 10
@export var wagon_length: float = 25.0
@export var connector_length: float = 3.0

var score: int = 0:
	set(value):
		score = value
		score_updated.emit(score)
		if score >= score_to_win:
			_enter_state(GameState.GAME_WON)

var current_wagon_num: int = 0
var wagon_instances: Array[Wagon] = []
var connector_instances: Array[WagonConnector] = []
var player_current_connector: WagonConnector = null

var wagon_being_attempted: Wagon = null
var connector_of_origin: WagonConnector = null

enum GameState { WAITING_TO_START, SETUP, IN_CONNECTOR, IN_WAGON, GAME_WON }
var current_state: GameState = GameState.WAITING_TO_START
var is_game_started: bool = false

func _ready() -> void:
	if not player or not start_connector:
		push_error("Player або Start Connector не призначені в TrainManager!")
		return
	
	start_connector.player_entered.connect(_on_game_start_triggered, CONNECT_ONE_SHOT)
	print("Train Manager is ready. Ready for start condition")

func _enter_state(new_state: GameState) -> void:
	if current_state == new_state: return
	current_state = new_state
	
	print("Enter state ", GameState.keys()[new_state])
	match current_state:
		GameState.SETUP:
			call_deferred("_initialize_train")
		GameState.IN_CONNECTOR:
			call_deferred("_update_world_around_player")
		GameState.IN_WAGON:
			pass
		GameState.GAME_WON:
			print("You win. Emergency brake is now showing in wagon")
			for wagon in wagon_instances:
				wagon.activate_emergency_brake()
			game_won.emit()

func _on_game_start_triggered(_connector: WagonConnector) -> void:
	if is_game_started: return
	is_game_started = true
	print("Game Started!")
	if demo_vagons.size() > 1:
		if is_instance_valid(demo_vagons[1]):
			demo_vagons[1].queue_free()
		demo_vagons.pop_back()
		print("Removing demo wagons:", demo_vagons.size())
	player_current_connector = start_connector
	_enter_state(GameState.SETUP)

func _initialize_train() -> void:
	connector_instances.append(start_connector)
	
	var last_connector = start_connector
	for i in range(wagons_to_spawn):
		var wagon_num = i + 1
		var new_nodes = _spawn_section(wagon_num, last_connector, true)
		
		# Зв'язуємо нові вузли з попередніми
		new_nodes.wagon.entry_connector = last_connector
		last_connector.set_wagon_after(new_nodes.wagon)
		
		wagon_instances.append(new_nodes.wagon)
		connector_instances.append(new_nodes.connector)
		
		last_connector = new_nodes.connector
		
	current_wagon_num = 1
	_enter_state(GameState.IN_CONNECTOR)

func _update_world_around_player() -> void:
	# 1. Оновлення (пере-створення) вагонів біля гравця
	reset_all_wagon_doors()
	_reroll_adjacent_wagons(player_current_connector)
	
	# 2. Перевірка, чи потрібно зміщувати "вікно" активних вагонів
	var player_connector_index = connector_instances.find(player_current_connector)
	if player_connector_index == -1:
		push_error("Поточний конектор гравця не знайдено в масиві!")
		return
	
	var forward_spawn_threshold = wagons_to_spawn - 2
	var backward_spawn_threshold = 2
	
	# --- ЛОГІКА РУХУ ВПЕРЕД ---
	if player_connector_index >= forward_spawn_threshold:
		var connector_to_remove = connector_instances.pop_front()
		var wagon_to_remove = wagon_instances.pop_front()
		if is_instance_valid(connector_to_remove): connector_to_remove.queue_free()
		if is_instance_valid(wagon_to_remove): wagon_to_remove.queue_free()

		var last_connector = connector_instances.back()
		var last_wagon = wagon_instances.back()
		var new_wagon_num = last_wagon.wagon_number + 1
		
		var new_nodes = _spawn_section(new_wagon_num, last_connector, true)
		new_nodes.wagon.entry_connector = last_connector
		last_connector.set_wagon_after(new_nodes.wagon)
		
		wagon_instances.append(new_nodes.wagon)
		connector_instances.append(new_nodes.connector)

	# --- ЛОГІКА РУХУ НАЗАД ---
	elif player_connector_index <= backward_spawn_threshold and player_current_connector != start_connector:
		var connector_to_remove = connector_instances.pop_back()
		var wagon_to_remove = wagon_instances.pop_back()
		if is_instance_valid(connector_to_remove): connector_to_remove.queue_free()
		if is_instance_valid(wagon_to_remove): wagon_to_remove.queue_free()
		
		var first_connector = connector_instances.front()
		var first_wagon = wagon_instances.front()
		var new_wagon_num = first_wagon.wagon_number - 1
		
		var new_nodes = _spawn_section(new_wagon_num, first_connector, false)
		new_nodes.connector.set_wagon_after(first_wagon)
		first_wagon.entry_connector = new_nodes.connector
		
		wagon_instances.push_front(new_nodes.wagon)
		connector_instances.push_front(new_nodes.connector)


func _spawn_section(number: int, anchor_connector: WagonConnector, is_forward: bool) -> Dictionary:
	var wagon_data = _get_wagon_data_for_number(number)
	if not wagon_data or not wagon_data.wagon_scene:
		push_error("Не вдалося отримати WagonData або сцена вагона порожня для номера %d" % number)
		return {}

	# Розрахунок позицій відносно "якоря"
	var direction = Vector3.RIGHT if is_forward else Vector3.LEFT
	var wagon_pos = anchor_connector.global_position + direction * (connector_length / 2 + wagon_length / 2)
	var connector_pos = anchor_connector.global_position + direction * (connector_length + wagon_length)

	# --- Створюємо вагон ---
	var new_wagon: Wagon = wagon_data.wagon_scene.instantiate()
	new_wagon.name = "Wagon_%d" % number
	add_child(new_wagon)
	new_wagon.global_position = wagon_pos
	new_wagon.setup(number, wagon_data)

	# --- Створюємо конектор ---
	var new_connector: WagonConnector = connector_scene.instantiate()
	new_connector.name = "Connector_%d" % number
	add_child(new_connector)
	new_connector.global_position = connector_pos
	
	# --- Зв'язуємо їх логічно ---
	new_wagon.exit_connector = new_connector
	new_connector.set_wagon_before(new_wagon)
	new_connector.player_entered.connect(_on_player_entered_connector)
	new_wagon.player_entered_tambour.connect(_on_player_entered_tambour)
	
	return {"wagon": new_wagon, "connector": new_connector}

func _on_player_entered_tambour(wagon: Wagon, tambour_index: int) -> void:
	if current_state == GameState.IN_CONNECTOR:
		wagon_being_attempted = wagon
		connector_of_origin = wagon.entry_connector if tambour_index == 0 else wagon.exit_connector
		wagon._apply_anomaly()
		_enter_state(GameState.IN_WAGON)
	elif current_state == GameState.IN_WAGON and wagon == wagon_being_attempted:
		var entered_from_front = (connector_of_origin == wagon.entry_connector) 
		var is_now_at_back_tambour = (tambour_index == 1) 
		if entered_from_front and is_now_at_back_tambour:
			wagon.lock_tambour_doors()
		elif not entered_from_front and not is_now_at_back_tambour:
			wagon.lock_tambour_doors()

func _on_player_entered_connector(connector: WagonConnector) -> void:
	player_current_connector = connector
	if not is_game_started: return
	if demo_vagons.size() > 0:
		if is_instance_valid(demo_vagons[0]):
			demo_vagons[0].queue_free()
		demo_vagons.pop_front()
	if current_state == GameState.IN_WAGON:
		if connector != connector_of_origin:
			print("Wagon #%d traversed!" % wagon_being_attempted.wagon_number)
			self.score += 1
			print("Current score: ", self.score)
			if connector == wagon_being_attempted.exit_connector:
				# Рухався вперед: увійшов через entry, вийшов через exit. Блокуємо entry.
				wagon_being_attempted.close_doors_without_locking()
			else:
				# Рухався назад: увійшов через exit, вийшов через entry. Блокуємо exit.
				wagon_being_attempted.close_doors_without_locking()
		else:
			print("Player retreated from wagon #%d" % wagon_being_attempted.wagon_number)
			if is_instance_valid(wagon_being_attempted):
				wagon_being_attempted.unlock_doors()
		# Скидаємо відстеження
		wagon_being_attempted = null
		connector_of_origin = null
	else:
		var wagon_before = connector.get_wagon_before()
		var wagon_after = connector.get_wagon_after()
		if is_instance_valid(wagon_before):
			wagon_before.unlock_tambour_doors()
		if is_instance_valid(wagon_after):
			wagon_after.unlock_tambour_doors()
	
	_enter_state(GameState.IN_CONNECTOR)

func reset_all_wagon_doors():
	for wagon in wagon_instances:
		if is_instance_valid(wagon):
			wagon.close_doors_without_locking()

func _reroll_adjacent_wagons(connector: WagonConnector) -> void:
	print("Rerolling anomalies around connector %s" % connector.name)
	var wagon_before = connector.get_wagon_before()
	var wagon_after = connector.get_wagon_after()
	
	if is_instance_valid(wagon_before):
		var new_data_before = _get_wagon_data_for_number(wagon_before.wagon_number)
		if new_data_before:
			wagon_before.setup(wagon_before.wagon_number, new_data_before)
			
	if is_instance_valid(wagon_after):
		var new_data_after = _get_wagon_data_for_number(wagon_after.wagon_number)
		if new_data_after:
			wagon_after.setup(wagon_after.wagon_number, new_data_after)

func close_and_lock_all_doors():
	for wagon in wagon_instances:
		if is_instance_valid(wagon):
			wagon.close_and_lock_doors()	

func close_all_doors():
	for wagon in wagon_instances:
		if is_instance_valid(wagon):
			wagon.close_doors_without_locking()	

func reset_all_locks():
	for wagon in wagon_instances:
		if is_instance_valid(wagon):
			wagon.unlock_doors()

func _get_wagon_data_for_number(num: int) -> WagonData:
	if num == 1 and first_anomaly_wagon: return first_anomaly_wagon
	if reserved_wagons.has(num): return reserved_wagons[num]
	if initial_wagon_pool: return initial_wagon_pool.pick_random()
	return null
