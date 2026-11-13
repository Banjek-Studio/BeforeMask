extends Node

## Signal notifying about player death.
#signal player_died

## Reference to the player.
var player: Player
## Reference to the spawn point.
var spawn_point: Node3D

## Reference to the death screen UI element (must be of type CanvasLayer).
@export var death_screen: CanvasLayer

func _ready():
	if death_screen:
		death_screen.hide()
	else:
		push_warning("Death screen is not assigned in GameManager!")

## This function is called when the player dies.
func _on_player_died():
	print("GameManager: Player has died.")
	if death_screen:
		death_screen.show()
	
	# Wait 3 seconds before respawning.
	await get_tree().create_timer(3.0).timeout
	_respawn_player()

func _respawn_player():
	if death_screen:
		death_screen.hide()
		
	if is_instance_valid(player) and is_instance_valid(spawn_point):
		player.respawn(spawn_point.global_transform)
		print("GameManager: Player has respawned.")
		# Logic for WagonManager to "reset" the current wagon can be added here.
	else:
		# If something goes wrong (e.g., no spawn point), reload the scene.
		print("Error: Player or spawn_point is invalid. Reloading scene.")
		get_tree().reload_current_scene()

## This function is called from the player to register them.
func register_player(player_node: Player):
	self.player = player_node
	if not player_node.died.is_connected(_on_player_died):
		player_node.died.connect(_on_player_died)

## This function is called from WagonManager to set where the player should appear.
func set_spawn_point(point: Node3D):
	self.spawn_point = point
