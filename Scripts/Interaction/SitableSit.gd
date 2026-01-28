extends Node3D  
class_name SitableSeat 

@export var stand_offset: Vector3 = Vector3(0, 0, 1.5)
@export var rotation_offset_degrees: float = 0.0 

var is_occupied: bool = false
var player_original_position: Vector3 = Vector3.ZERO
var player_original_rotation: Vector3 = Vector3.ZERO
var current_player: Player = null

@onready var collision_shape_3d: CollisionShape3D = $SitableArea/CollisionShape3D
@onready var occupation_raycast: RayCast3D = $OccupationRayCast
@onready var sitable_area: Sitable = $SitableArea 

func get_sit_position() -> Vector3:
	return global_position 

func get_sit_rotation() -> Vector3:
	var new_rotation = global_rotation
	new_rotation.y += deg_to_rad(rotation_offset_degrees)
	return new_rotation

func get_stand_position() -> Vector3:
	return global_position + transform.basis * stand_offset

func is_seat_available() -> bool:
	if occupation_raycast and occupation_raycast.is_colliding():
		return false
	return not is_occupied

func set_player_original_transform(player_pos: Vector3, player_rot: Vector3) -> void:
	player_original_position = player_pos
	player_original_rotation = player_rot

func _on_sitable_area_try_to_sit() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return

	if is_occupied and current_player == player:
		if player.has_method("stand_up"):
			player.stand_up()
	elif not is_occupied and is_seat_available():
		if player.has_method("sit_down"):
			if collision_shape_3d:
				collision_shape_3d.disabled = true
				get_tree().create_timer(1.0).timeout.connect(_enable_collision)
			
			player.sit_down(self) 
			var sit_sound = get_node_or_null("SitSound")
			if sit_sound:
				sit_sound.play()

func _enable_collision():
	if collision_shape_3d:
		collision_shape_3d.disabled = false

func force_unsit():
	if is_occupied and current_player:
		is_occupied = false
		current_player = null
