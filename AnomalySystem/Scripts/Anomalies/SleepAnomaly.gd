extends BaseAnomalyObject
class_name SleepAnomaly

@export var effect_duration: float = 5.0

var world_environment: WorldEnvironment
var original_dof_blur_amount: float = 0.0
var original_adjustment_saturation: float = 1.0
var original_dof_far_enabled: bool = false

func _ready():
	world_environment = get_tree().current_scene.find_child("WorldEnvironment", false, false)
	if world_environment:
		var cam_attrs = world_environment.camera_attributes as CameraAttributesPractical
		if cam_attrs:
			original_dof_blur_amount = cam_attrs.dof_blur_amount
			original_dof_far_enabled = cam_attrs.dof_blur_far_enabled
			original_adjustment_saturation = world_environment.environment.adjustment_saturation

func activate():
	super.activate()
	if not world_environment:
		return
	var cam_attrs = world_environment.camera_attributes as CameraAttributesPractical
	if not cam_attrs:
		return

	# Увімкнути DOF far, якщо вимкнено
	cam_attrs.dof_blur_far_enabled = true

	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam_attrs, "dof_blur_amount", 0.5, effect_duration)
	tween.parallel().tween_property(world_environment.environment, "adjustment_saturation", 0.2, effect_duration)
	tween.tween_callback(deactivate)

func deactivate():
	if not is_active:
		return
	is_active = false

	if not world_environment:
		return
	var cam_attrs = world_environment.camera_attributes as CameraAttributesPractical
	if not cam_attrs:
		return

	var tween = create_tween().set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cam_attrs, "dof_blur_amount", original_dof_blur_amount, effect_duration / 2)
	tween.parallel().tween_property(world_environment.environment, "adjustment_saturation", original_adjustment_saturation, effect_duration / 2)
	# Відновити стан увімкнення DOF
	tween.tween_callback(func ():
		cam_attrs.dof_blur_far_enabled = original_dof_far_enabled
		hide()
	)
