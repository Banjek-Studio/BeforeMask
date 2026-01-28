extends BaseAnomalyObject
class_name ShadowAnomaly

## Час в секундах, який гравець може перебувати у вагоні до появи Тіні.
@export var activation_delay: float = 15.0
## Об'єкт, що представляє собою Тінь (наприклад, Area3D з чорним шейдером).
@export var shadow_object: Area3D
## Швидкість руху Тіні.
@export var speed: float = 1.0

var spawn_timer: Timer
var player_ref: Player
var flashlight_ref # Посилання на вузол ліхтарика гравця

func _ready():
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_spawn_shadow)
	
	if shadow_object:
		shadow_object.hide()
		shadow_object.body_entered.connect(_on_shadow_touch)

func activate():
	super.activate()
	player_ref = get_tree().get_first_node_in_group("Player") as Player
	if player_ref:
		# Припускаємо, що ліхтарик є дочірнім вузлом гравця
		flashlight_ref = player_ref.find_child("Flashlight") 
	
	spawn_timer.start(activation_delay)
	print("The air grows cold. You feel watched.")

func deactivate():
	super.deactivate()
	spawn_timer.stop()
	if shadow_object and is_instance_valid(shadow_object):
		shadow_object.hide()

func _spawn_shadow():
	if not is_active or not parent_wagon: return
	
	print("A shadow emerges...")
	shadow_object.show()
	# Визначаємо, звідки почнеться рух Тіні - від входу чи виходу вагона
	var start_pos = parent_wagon.entry_tambour_door.global_position
	var end_pos = parent_wagon.exit_tambour_door.global_position
	
	shadow_object.global_position = start_pos
	
	var tween = create_tween().set_parallel()
	tween.tween_property(shadow_object, "global_position", end_pos, (end_pos - start_pos).length() / speed)

func _on_shadow_touch(body: Node3D):
	if body == player_ref:
		var is_flashlight_on = flashlight_ref and flashlight_ref.is_on
		
		if is_flashlight_on:
			print("The flashlight flickers as you pass through the shadow.")
			if flashlight_ref.has_method("drain_battery"):
				flashlight_ref.drain_battery(10.0) # Витрата батареї x10
		else:
			print("The shadow consumes you.")
			player_ref.kill()
