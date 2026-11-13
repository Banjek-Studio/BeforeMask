extends BasePickableObject
class_name FlashlightItem

@export_category("Light Settings")
@export var is_on: bool = false
@export var spotlights: Array[SpotLight3D]


@export_category("Battery")
@export var battery: Battery
@export var drain_rate: float = 0.5
@export var flicker_threshold: float = 20.0
@onready var energy_slider: MeshInstance3D = $Item/EnergySlider
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

@onready var material_instance: StandardMaterial3D = energy_slider.mesh.material

func _ready() -> void:
	if is_on:
		turn_on()
	if !is_on:
		turn_off()

func _process(delta: float) -> void:
	if is_on and battery:
		battery.capability = max(0, battery.capability - drain_rate * delta)
		_update_energy_visuals()
		if battery.capability == 0:
			turn_off()
	if not is_held:
		return
	
	if Input.is_action_just_pressed("switch_mode"):
		_play_switch_sound()
		

func drain_battery(multiplier: float):
	if is_on and battery:
		# Instantly subtract charge amount equivalent to 1 second of operation,
		# multiplied by the multiplier.
		var drain_amount = drain_rate * multiplier
		battery.capability = max(0, battery.capability - drain_amount)
		print("Flashlight battery drained by a burst. Remaining: %f" % battery.capability)
		_update_energy_visuals()

func turn_on() -> void:
	if battery and battery.capability > 0:
		is_on = true
		_update_light_state()

func turn_off() -> void:
	is_on = false
	_update_light_state()

func _play_switch_sound() -> void:
	audio_stream_player.play()

func _update_light_state() -> void:
	for light in spotlights:
		if light:
			light.visible = is_on

func _update_energy_visuals() -> void:
	if not battery or not material_instance:
		return
		
	var percentage: float = (battery.capability / battery.max_capability) * 100.0
	
	if percentage > 50.0:
		material_instance.albedo_color = Color.GREEN
	elif percentage > flicker_threshold:
		material_instance.albedo_color = Color.YELLOW
	elif percentage < flicker_threshold and percentage != 0:
		material_instance.albedo_color = Color.RED
	else:
		material_instance.albedo_color = Color.BLACK
		

func _on_audio_stream_player_finished() -> void:
	if is_on:
		turn_off()
	else:
		turn_on()
