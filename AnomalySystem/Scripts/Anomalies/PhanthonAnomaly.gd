extends BaseAnomalyObject
class_name PhantomAnomaly

## Меш фантома, який буде рухатись
@export var phantom_mesh: MeshInstance3D
## Швидкість руху фантома
@export var speed: float = 2.0

var start_pos: Vector3
var end_pos: Vector3

func _ready():
	if phantom_mesh:
		phantom_mesh.hide()
	# Визначаємо початкову та кінцеву точки руху в межах вагона
	start_pos = Vector3(-10, 1, 0) # Починається за однією стіною
	end_pos = Vector3(10, 1, 0)   # Закінчується за іншою

func activate():
	super.activate()
	if phantom_mesh:
		phantom_mesh.global_position = self.global_position + start_pos
		phantom_mesh.show()
		
		# Створюємо анімацію руху
		var tween = create_tween().set_trans(Tween.TRANS_LINEAR)
		tween.tween_property(phantom_mesh, "global_position", self.global_position + end_pos, (end_pos.x - start_pos.x) / speed)
		tween.tween_callback(phantom_mesh.hide)

func deactivate():
	super.deactivate()
	if phantom_mesh:
		phantom_mesh.hide()
