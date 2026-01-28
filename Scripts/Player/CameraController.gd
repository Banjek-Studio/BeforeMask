extends Node3D

@export var player_body: CharacterBody3D
@export var hand: Node3D

@export_category("Camera")
@export var mouse_sensitivity: float = 0.2
@export var zoom_fov: float = 40.0
@export var zoom_speed: float = 5.0
@export var normal_fov: float = 60.0
@export var sitting_head_yaw_limit: float = 90.0

@export_category("Sway")
@export var sway_amount: float = 1.5
@export var sway_lerp_speed: float = 6.0

@onready var camera: Camera3D = $"../HeadBob/Camera3D"
@onready var head: Node3D = $".."

var pitch: float = 0.0
var is_zooming: bool = false
var sway_target: Vector3 = Vector3.ZERO

func _ready() -> void:
	normal_fov = camera.fov
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_look(event)
		_handle_sway(event)

func _physics_process(delta: float) -> void:
	_update_zoom(delta)
	_update_sway(delta)

func _handle_mouse_look(event: InputEventMouseMotion) -> void:
	if player_body and player_body.is_in_transition:
		return

	pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -90, 90)
	head.rotation_degrees.x = pitch
	
	if player_body and player_body.is_sitting:
		var new_head_yaw = head.rotation_degrees.y - event.relative.x * mouse_sensitivity
		head.rotation_degrees.y = clamp(new_head_yaw, -sitting_head_yaw_limit, sitting_head_yaw_limit)
	else:
		player_body.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

func _handle_sway(event: InputEventMouseMotion) -> void:
	if not hand:
		return
	sway_target.y = -event.relative.x * sway_amount
	sway_target.x = -event.relative.y * sway_amount

func _update_sway(delta: float) -> void:
	if not hand:
		return
	sway_target = sway_target.lerp(Vector3.ZERO, delta * sway_lerp_speed)
	hand.rotation_degrees = hand.rotation_degrees.lerp(sway_target, delta * sway_lerp_speed)

func _update_zoom(delta: float) -> void:
	is_zooming = Input.is_action_pressed("zoom_in")
	var target_fov = zoom_fov if is_zooming else normal_fov
	camera.fov = lerp(camera.fov, target_fov, zoom_speed * delta)

func reset_camera_state() -> void:
	pitch = 0.0
	head.rotation = Vector3.ZERO
