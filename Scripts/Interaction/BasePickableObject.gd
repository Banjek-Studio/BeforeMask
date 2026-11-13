extends RigidBody3D
class_name BasePickableObject

@onready var inventory: Inventory = get_node("/root/InventorySystem")
@export var item_data: ItemData
@export var has_parent: bool = false
@export var is_held: bool = false

func _ready() -> void:
	if not item_data:
		push_error("BasePickableObject has no item_data assigned")
		return
	item_data = item_data.duplicate()

func set_held(value: bool) -> void:
	is_held = value
	
	if is_held:
		freeze = true # stops physics but not the script
		for child in get_children():
			if child is CollisionShape3D:
				child.disabled = true
	else:
		freeze = false
		for child in get_children():
			if child is CollisionShape3D:
				child.disabled = false

func _apply_item_scale() -> void:
	if item_data and item_data.item_scale != Vector3.ZERO:
		if has_node("Item"):
			$Item.scale = item_data.item_scale

func _play_pickup_sound() -> void:
	if has_node("PickupSound"):
		$PickupSound.play()

func _on_pickable_area_item_picked_up() -> void:
	var added = false
	if item_data and inventory:
		added = inventory.add_item(item_data)
	if !added:
		return
	if has_node("PickableArea/CollisionShape3D"):
		$PickableArea/CollisionShape3D.disabled = true
		$CollisionShape3D.disabled = true
	else:
		push_error("Missing item_data or inventory reference")
	hide()
	_play_pickup_sound()

func _on_pickup_sound_finished() -> void:
	if has_parent:
		$"..".queue_free()
	else:
		queue_free()
