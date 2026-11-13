extends Node3D
class_name HeadBob

@export_category("HeadBob Settings")
@export var enabled: bool = true
@export var head_bob_strength: float = 0.07
@export var recovery_speed: float = 0.1

@export_group("Movement Frequencies", "bob_")
@export var bob_walk_frequency: float = 1.8
@export var bob_slow_walk_frequency: float = 1.4
@export var bob_crouch_frequency: float = 1.1

var bob_time: float = 0.0
var player: CharacterBody3D
var initial_position: Vector3

func _ready() -> void:
	player = get_parent().get_parent() as CharacterBody3D
	if not player:
		push_error("HeadBob: failed to find player node (Player).")
		set_process(false)
		return
		
	initial_position = position

func _process(delta: float) -> void:
	if not enabled or not player:
		position = initial_position
		return
	
	var horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
	var velocity_magnitude = horizontal_velocity.length()
	
	if velocity_magnitude > 0.1 and not player.is_sitting and player.is_on_floor():
		var current_bob_frequency: float = bob_walk_frequency
		if player.crouching:
			current_bob_frequency = bob_crouch_frequency
		elif player.is_slow_walking:
			current_bob_frequency = bob_slow_walk_frequency
			
		bob_time += delta * current_bob_frequency
		
		var vertical_bob = sin(bob_time * 2.0) * head_bob_strength
		var horizontal_sway = cos(bob_time) * head_bob_strength
		
		var target_pos = initial_position + Vector3(horizontal_sway, vertical_bob, 0)
		position = position.lerp(target_pos, 0.2)
		
	else:
		position = position.lerp(initial_position, recovery_speed)
		bob_time = 0.0
