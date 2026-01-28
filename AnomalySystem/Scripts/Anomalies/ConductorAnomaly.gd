extends BaseAnomalyObject
class_name ConductorAnomaly

## Area3D для виявлення зіткнення з гравцем.
@export var collision_area: Area3D

func _ready():
	if collision_area:
		collision_area.body_entered.connect(_on_player_contact)

func activate():
	super.activate()
	# Тут може бути логіка появи або патрулювання Провідника
	print("A conductor is checking tickets in this wagon.")

func deactivate():
	super.deactivate()

func _on_player_contact(body: Node3D):
	if not is_active: return
	
	if body.is_in_group("Player"):
		var player = body as Player
		print("Conductor: 'Your ticket, please!'")
		
		# Припускаємо, що інвентар - це масив або словник
		var inventory = player.get_inventory()
		var had_money = "money" in inventory # Приклад перевірки
		
		# Конфіскуємо все, крім ліхтарика
		if inventory.has_method("confiscate_all_but_flashlight"):
			inventory.confiscate_all_but_flashlight()
		
		if not had_money:
			print("Conductor: 'No money? Then your soul will do.'")
			player.kill()
		else:
			print("Conductor: 'Move along.'")
		
		# Провідник зникає або йде після взаємодії
		deactivate()
