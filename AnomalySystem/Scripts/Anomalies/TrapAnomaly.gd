extends BaseAnomalyObject
class_name TrapAnomaly

## Область, яка спрацює як пастка
@export var trap_area: Area3D
## Звук, який програється при спрацюванні
@export var trigger_sound: AudioStreamPlayer3D

var has_triggered: bool = false
var activated: bool = false
func _ready():
	if trap_area:
		trap_area.body_entered.connect(_on_trap_area_body_entered)

func activate():
	super.activate()
	activated = true
	has_triggered = false
	# Робимо пастку активною (вмикаємо її CollisionShape)
	if trap_area:
		trap_area.monitoring = true

func deactivate():
	super.deactivate()
	activated = false
	# Вимикаємо пастку
	if trap_area:
		trap_area.monitoring = false

func _on_trap_area_body_entered(body: Node3D):
	if has_triggered: return
	if !activated: return
	if body.is_in_group("Player"):
		has_triggered = true
		print("Trap triggered!")
		if trigger_sound:
			trigger_sound.play()
		
		# Тут можна додати будь-яку логіку: нанести шкоду, закрити двері і т.д.
		# Наприклад, тимчасово заблокуємо двері вагона
		parent_wagon.close_and_lock_doors()
		
		# І розблокуємо їх через 3 секунди
		await get_tree().create_timer(3.0).timeout
		parent_wagon.unlock_doors()
