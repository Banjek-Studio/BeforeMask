extends Node
class_name FootstepController

@export_category("Node References")
@export var player: CharacterBody3D
@export var footstep_player: AudioStreamPlayer3D

@export_category("Footstep Settings")
@export var min_step_interval: float = 0.5

@export_group("Step Frequencies", "step_")
@export var step_walk_frequency: float = 4.0
@export var step_slow_walk_frequency: float = 2.1
@export var step_crouch_frequency: float = 1.1

@export_group("Audio Volumes (dB)", "volume_")
@export var volume_walk_db: float = 0.0
@export var volume_slow_walk_db: float = 20.0
@export var volume_crouch_db: float = 30.0

@export_group("Audio Streams (Randomizers)")
@export var walk_stream: AudioStreamRandomizer
@export var slow_walk_stream: AudioStreamRandomizer
@export var crouch_stream: AudioStreamRandomizer

var step_time: float = 0.0
var last_step_cycle_value: float = 0.0
var footstep_cooldown: float = 0.0

func _ready() -> void:
	if not player:
		set_process(false)
	if not footstep_player:
		set_process(false)

func _process(delta: float) -> void:
	if footstep_cooldown > 0:
		footstep_cooldown -= delta

	if not is_instance_valid(player):
		return
	
	var horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
	var velocity_magnitude = horizontal_velocity.length()
	
	if velocity_magnitude > 0.1 and not player.is_sitting and player.is_on_floor():
		var current_step_frequency: float = step_walk_frequency
		
		if player.crouching:
			current_step_frequency = step_crouch_frequency
		elif player.is_slow_walking:
			current_step_frequency = step_slow_walk_frequency
		
		step_time += delta * current_step_frequency
		
		_handle_footsteps()
	else:
		step_time = 0.0
		last_step_cycle_value = 0.0

func _handle_footsteps() -> void:
	if footstep_cooldown > 0:
		return

	var current_step_cycle_value = sin(step_time * 2.0)
	
	if last_step_cycle_value <= 0 and current_step_cycle_value > 0:
		_play_footstep_sound()
	
	last_step_cycle_value = current_step_cycle_value

func _play_footstep_sound() -> void:
	if not footstep_player or footstep_player.is_playing():
		return

	var sound_stream: AudioStream
	var target_volume_db: float

	if player.crouching:
		sound_stream = crouch_stream
		target_volume_db = volume_crouch_db
	elif player.is_slow_walking:
		sound_stream = slow_walk_stream
		target_volume_db = volume_slow_walk_db
	else:
		sound_stream = walk_stream
		target_volume_db = volume_walk_db
		
	if sound_stream:
		footstep_player.stream = sound_stream
		footstep_player.volume_db = target_volume_db
		footstep_player.pitch_scale = randf_range(0.95, 1.05)
		footstep_player.play()
		footstep_cooldown = min_step_interval
