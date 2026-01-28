extends Node

## Сигнал, що сповіщає про смерть гравця.
#signal player_died

## Посилання на гравця.
var player: Player
## Посилання на точку відродження.
var spawn_point: Node3D

## Посилання на UI-елемент екрану смерті (має бути типу CanvasLayer).
@export var death_screen: CanvasLayer

func _ready():
	if death_screen:
		death_screen.hide()
	else:
		push_warning("Death screen is not assigned in GameManager!")

## Ця функція викликається, коли гравець помирає.
func _on_player_died():
	print("GameManager: Player has died.")
	if death_screen:
		death_screen.show()
	
	# Чекаємо 3 секунди перед відродженням.
	await get_tree().create_timer(3.0).timeout
	_respawn_player()

func _respawn_player():
	if death_screen:
		death_screen.hide()
		
	if is_instance_valid(player) and is_instance_valid(spawn_point):
		player.respawn(spawn_point.global_transform)
		print("GameManager: Player has respawned.")
		# Тут можна додати логіку для WagonManager, щоб "скинути" поточний вагон.
	else:
		# Якщо щось пішло не так (наприклад, немає точки спавну), перезавантажуємо сцену.
		print("Error: Player or spawn_point is invalid. Reloading scene.")
		get_tree().reload_current_scene()

## Ця функція викликається з гравця, щоб зареєструвати його.
func register_player(player_node: Player):
	self.player = player_node
	if not player_node.died.is_connected(_on_player_died):
		player_node.died.connect(_on_player_died)

## Ця функція викликається з WagonManager, щоб встановити, де гравець має з'явитися.
func set_spawn_point(point: Node3D):
	self.spawn_point = point
