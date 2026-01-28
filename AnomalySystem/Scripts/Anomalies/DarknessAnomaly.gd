extends BaseAnomalyObject
class_name DarknessAnomaly

## Посилання на WorldEnvironment, яким будемо керувати.
@onready var world_environment: WorldEnvironment = get_tree().current_scene.find_child("WorldEnvironment", false, false) as WorldEnvironment

var original_ambient_color: Color
var original_fog_density: float

func _ready():
	# Зберігаємо початкові налаштування світу, щоб їх можна було відновити
	if world_environment:
		original_ambient_color = world_environment.environment.ambient_light_color
		original_fog_density = world_environment.environment.fog_density

func activate():
	super.activate() # Викликаємо базову функцію (робить show())
	if world_environment:
		# Робимо вагон темним і туманним
		world_environment.environment.ambient_light_color = Color.BLACK
		world_environment.environment.fog_density = 0.5
		print("It's getting dark...")

func deactivate():
	super.deactivate() # Викликаємо базову функцію (робить hide())
	if world_environment:
		# Повертаємо світло та туман до початкових значень
		world_environment.environment.ambient_light_color = original_ambient_color
		world_environment.environment.fog_density = original_fog_density
