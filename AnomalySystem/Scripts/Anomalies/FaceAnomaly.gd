extends BaseAnomalyObject
class_name FaceAnomaly

## Спрайт або меш з обличчям
@export var face_sprite: Sprite3D
## Звук появи
@export var jumpscare_sound: AudioStreamPlayer3D

func _ready():
	if face_sprite:
		face_sprite.hide()

func activate():
	super.activate()
	# Ця аномалія спрацьовує один раз і деактивується
	var player = get_tree().get_first_node_in_group("Player")
	if not player: 
		deactivate()
		return

	if face_sprite:
		# Розміщуємо обличчя прямо перед камерою гравця
		var camera = player.find_child("Camera3D", true, false)
		if camera:
			face_sprite.global_transform = camera.global_transform
			face_sprite.global_position += camera.global_transform.basis.z * -1 # Трохи попереду камери
			
			if jumpscare_sound:
				jumpscare_sound.play()
			
			face_sprite.show()
			
			# Ховаємо обличчя через короткий проміжок часу
			await get_tree().create_timer(0.25).timeout
			face_sprite.hide()
			
	# Деактивуємо себе, щоб не спрацьовувати знову
	deactivate()

func deactivate():
	super.deactivate()
	if face_sprite:
		face_sprite.hide()
