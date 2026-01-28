extends CharacterBody3D
class_name Player

signal died

@export_category("UI and Inventory")
@export var player_inventory: InventoryUI
@onready var inventory: Inventory = $"/root/InventorySystem"
@onready var item_database: Node = $"/root/ItemDatabase"
@export var hand_position: Node3D

@export_category("Components")
@onready var head: Node3D = $Head
@onready var camera_controller = $Head/CameraController
@onready var crouch_raycasts: Node3D = $CrouchRaycasts
@onready var camera: Camera3D = $Head/HeadBob/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

@export_category("Movement")
@export var speed: float = 7.0
@export var slow_walk_speed: float = 5.0
@export var crouch_speed: float = 3.0
@export var jump_acceleration: float = 5.0

@export_category("Input")
@export var hold_activation_time: float = 0.2

var crouch_config = { "head_y": 1.3, "collision_height": 1.3, "raycast_offset_y": 1.0 }
var stand_config = { "head_y": 1.75, "collision_height": 1.6 }

var is_alive: bool = true
var sit_head_y: float = 0.7
var crouching: bool = false
var can_uncrouch: bool = true
var is_slow_walking: bool = false

var is_sitting: bool = false
var is_in_transition: bool = false
var current_sitable_object: SitableSeat = null

var gravity: float
var current_speed: float
var slow_walk_hold_time: float = 0.0

var current_held_item: Node3D = null

func _ready() -> void:
	if get_tree().root.has_node("GameManager"):
		get_tree().root.get_node("GameManager").register_player(self)
	else:
		push_warning("GameManager not found in autoloads!")
	if inventory:
		inventory.item_equipped.connect(_on_item_equipped)
		inventory.item_unequipped.connect(_on_item_unequipped)
		
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	current_speed = speed
	_initialize_crouch_raycasts()
	player_inventory.setup(inventory)

func kill() -> void:
	if not is_alive: return # Захист від повторної смерті.
	is_alive = false
	print("Player has been killed.")
	
	# Вимикаємо фізику та обробку вводу, щоб гравець зупинився.
	set_physics_process(false)
	set_process_input(false)
	velocity = Vector3.ZERO
	
	# Посилаємо сигнал, що гравець помер. GameManager його зловить.
	died.emit()
	# Тут можна додати звук смерті або анімацію падіння.

func respawn(spawn_transform: Transform3D):
	is_alive = true
	global_transform = spawn_transform
	
	# Вмикаємо фізику та ввід назад.
	set_physics_process(true)
	set_process_input(true)
	
	print("Player has respawned.")

func get_inventory():
	return inventory

func get_flashlight() -> FlashlightItem:
	if current_held_item is FlashlightItem:
		return current_held_item as FlashlightItem
	return null

func _on_item_equipped(item_data: ItemData, _slot_index: int):
	_destroy_held_item()
	if item_data and hand_position:
		if item_database and item_database.item_scenes.has(item_data.item_id):
			current_held_item = item_database.item_scenes[item_data.item_id].instantiate()
			hand_position.add_child(current_held_item)
			current_held_item.add_to_group("equipped_item")
			if current_held_item.has_method("set_held") :
				current_held_item.set_held(true)
			print("Now holding: ", item_data.name)

func _find_node_of_class(start_node: Node, class_to_find: String) -> Node:
	if start_node.is_class(class_to_find):
		return start_node
	for child in start_node.get_children():
		var found = _find_node_of_class(child, class_to_find)
		if found:
			return found
	return null

func _on_item_unequipped(item_data: ItemData, _slot_index: int):
	_destroy_held_item()
	print("No longer holding: ", item_data.name)

func _destroy_held_item():
	if is_instance_valid(current_held_item):
		current_held_item.queue_free() # Безпечно видаляємо об'єкт зі сцени
		if current_held_item.is_in_group("equipped_item"):
			current_held_item.remove_from_group("equipped_item")
	current_held_item = null # Очищуємо змінну

func _input(event):
	if !is_alive:
		return
	if event.is_action_pressed("drop") and inventory.get_equipped_item():
		var drop_direction = -global_transform.basis.z
		var drop_position = global_position + drop_direction * 1.5 + Vector3(0, 1, 0)
		drop_equipped_item(drop_position, drop_direction)

func drop_equipped_item(new_position: Vector3, direction: Vector3, slot: int = -1) -> bool:
	var slot_index = inventory.equipped_slot
	if slot >= 0:
		slot_index = slot
	if slot_index < 0:
		return false
	var item_data = inventory.get_item_at(slot_index)
	if not item_data:
		return false
	var world_instance = item_database.item_scenes[item_data.item_id].instantiate()
	get_tree().current_scene.add_child(world_instance)
	world_instance.position = new_position
	call_deferred("update_held_state",world_instance)
	if direction != Vector3.ZERO:
		var rigidbody: RigidBody3D = _find_node_of_class(world_instance, "RigidBody3D")
		if rigidbody:
			_apply_throw_force(rigidbody, direction)
	
	inventory.remove_item(slot_index, 1)
	return true

func update_held_state(world_instance: Node):
	if world_instance.has_method("set_held"):
		world_instance.set_held(false)

func _apply_throw_force(item_instance: Node, direction: Vector3) -> void:
	var throw_force = 2.0
	var upward_force = 1.0
	
	if item_instance is RigidBody3D:
		var force_vector = direction.normalized() * throw_force + Vector3.UP * upward_force
		item_instance.linear_velocity = force_vector
		
		var random_torque = Vector3(
			randf_range(-5, 5),
			randf_range(-5, 5),
			randf_range(-5, 5)
		)
		item_instance.apply_torque_impulse(random_torque)
	
	elif item_instance.has_method("apply_impulse"):
		var force_vector = direction.normalized() * throw_force + Vector3.UP * upward_force
		item_instance.apply_impulse(force_vector)

func _process(_delta: float) -> void:
	if !is_alive:
		return
	if is_sitting:
		var stand_up_input = Input.is_action_pressed("move_forward") or \
							   Input.is_action_pressed("move_back") or \
							   Input.is_action_pressed("move_left") or \
							   Input.is_action_pressed("move_right")
		if stand_up_input:
			stand_up()
		return

func _physics_process(delta: float) -> void:
	if !is_alive:
		return
	if is_sitting:
		velocity = Vector3.ZERO
	else:
		_apply_crouch()
		_apply_gravity(delta)
		_handle_jump()
		_handle_movement()
		_update_crouch_state()
		_update_slow_walk(delta)

	if not is_sitting:
		move_and_slide()

func sit_down(sitable_object: SitableSeat) -> void:
	if is_sitting or not sitable_object or is_in_transition:
		return

	is_in_transition = true
	is_sitting = true
	current_sitable_object = sitable_object
	current_sitable_object.is_occupied = true
	current_sitable_object.current_player = self

	current_sitable_object.set_player_original_transform(global_position, global_rotation)

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "global_position", current_sitable_object.get_sit_position(), 0.5)

	var seat_rotation: Vector3 = current_sitable_object.get_sit_rotation()
	var target_body_rotation: Vector3 = Vector3(0, seat_rotation.y, 0)

	tween.parallel().tween_property(self, "global_rotation", target_body_rotation, 0.5)

	tween.parallel().tween_property(head, "rotation", Vector3.ZERO, 0.5)

	tween.parallel().tween_property(head, "position:y", sit_head_y, 0.5)

	await tween.finished
	
	if camera_controller:
		camera_controller.reset_camera_state()

	is_in_transition = false

func stand_up() -> void:
	if not is_sitting or not current_sitable_object or is_in_transition:
		return
		
	is_in_transition = true
	var object_to_stand_from = current_sitable_object

	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "global_position", object_to_stand_from.player_original_position, 0.5)
	tween.parallel().tween_property(head, "position:y", stand_config["head_y"], 0.5)
	tween.parallel().tween_property(self, "global_rotation", object_to_stand_from.player_original_rotation, 0.5)
	tween.parallel().tween_property(head, "rotation", Vector3(head.rotation.x, 0, 0), 0.5)
	
	await tween.finished
	
	is_sitting = false
	object_to_stand_from.is_occupied = false
	object_to_stand_from.current_player = null
	current_sitable_object = null
	
	is_in_transition = false

func _initialize_crouch_raycasts() -> void:
	crouch_raycasts.position.y = crouch_config["raycast_offset_y"]

func _update_crouch_state() -> void:
	can_uncrouch = true
	for raycast in crouch_raycasts.get_children():
		if raycast.is_colliding():
			can_uncrouch = false
			break
	crouching = Input.is_action_pressed("crouch")

func _apply_crouch() -> void:
	var config = crouch_config if crouching else stand_config
	var target_head_y = config["head_y"]
	var target_collision_height = config["collision_height"]
	head.position.y = lerp(head.position.y, target_head_y, 0.1)
	collision_shape.shape.height = lerp(collision_shape.shape.height, target_collision_height, 0.1)

func _update_slow_walk(delta: float) -> void:
	if Input.is_action_pressed("slow_walk"):
		slow_walk_hold_time += delta
		if slow_walk_hold_time >= hold_activation_time:
			is_slow_walking = true
	else:
		slow_walk_hold_time = 0.0
		is_slow_walking = false

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_acceleration

func _handle_movement() -> void:
	var movement_speed: float
	if crouching:
		movement_speed = crouch_speed
	elif is_slow_walking:
		movement_speed = slow_walk_speed
	else:
		movement_speed = speed
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if input_dir.y > 0:
		movement_speed *= 0.6
	elif input_dir.y == 0 and input_dir.x != 0:
		movement_speed *= 0.8
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)
