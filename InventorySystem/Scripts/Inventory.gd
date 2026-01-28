extends Node
class_name Inventory

signal inventory_updated
signal item_used(item_data: ItemData)
signal item_equipped(item_data: ItemData, slot_index: int)
signal item_unequipped(item_data: ItemData, slot_index: int)

@export var slots_count: int = 3
@export var slots: Array[ItemData] = []
@export var quantities: Array[int] = []

@onready var item_database: Node = $"/root/ItemDatabase"

var equipped_item: ItemData = null
var equipped_slot: int = -1

func _ready() -> void:
	initialize_slots()

func initialize_slots():
	slots.resize(slots_count)
	quantities.resize(slots_count)
	for i in range(slots_count):
		slots[i] = null
		quantities[i] = 0

func add_item(item_data: ItemData, quantity: int = 1) -> bool:
	if not item_data:
		return false
	# First try to stack with existing items
	if item_data.max_stack_size > 1:
		for i in range(slots_count):
			if slots[i] and slots[i].item_id == item_data.item_id and quantities[i] < item_data.max_stack_size:
				var space_available = item_data.max_stack_size - quantities[i]
				var to_add = min(quantity, space_available)
				quantities[i] += to_add
				quantity -= to_add
				inventory_updated.emit()
				if quantity <= 0:
					return true

	# Then try empty slots
	for i in range(slots_count):
		if slots[i] == null:
			slots[i] = item_data
			quantities[i] = min(quantity, item_data.max_stack_size)
			inventory_updated.emit()
			return true
	return false  # Inventory full

func remove_item(slot_index: int, quantity: int = 1) -> bool:
	if slot_index < 0 or slot_index >= slots_count:
		return false
	if slots[slot_index] == null:
		return false
	
	if slot_index == equipped_slot:
		unequip_item()
	
	quantities[slot_index] -= quantity
	if quantities[slot_index] <= 0:
		slots[slot_index] = null
		quantities[slot_index] = 0
	
	inventory_updated.emit()
	return true

func use_item(slot_index: int, _target: Node = null) -> bool:
	if slot_index < 0 or slot_index >= slots_count:
		return false
	if slots[slot_index] == null:
		return false
	
	var item_data = slots[slot_index]
	
	var success = item_data.use(self, slot_index)
	
	if success:
		item_used.emit(item_data)
	
	return success

func equip_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots_count:
		return false
	if slots[slot_index] == null:
		return false
	
	if equipped_item:
		unequip_item()
	
	equipped_item = slots[slot_index]
	equipped_slot = slot_index
	item_equipped.emit(equipped_item, slot_index)
	return true

func unequip_item() -> bool:
	if not equipped_item:
		return false
	
	var unequipped_item = equipped_item
	var unequipped_slot = equipped_slot
	
	equipped_item = null
	equipped_slot = -1
	item_unequipped.emit(unequipped_item, unequipped_slot)
	return true


func toggle_equip_item(slot_index: int) -> bool:
	if slot_index == equipped_slot:
		return unequip_item()
	else:
		return equip_item(slot_index)

func get_equipped_item() -> ItemData:
	return equipped_item

func get_item_at(slot_index: int) -> ItemData:
	if slot_index >= 0 and slot_index < slots_count:
		return slots[slot_index]
	return null

func get_quantity_at(slot_index: int) -> int:
	if slot_index >= 0 and slot_index < slots_count:
		return quantities[slot_index]
	return 0

func has_item(item_id: int) -> bool:
	for item in slots:
		if item and item.item_id == item_id:
			return true
	return false

func get_first_empty_slot() -> int:
	for i in range(slots_count):
		if slots[i] == null:
			return i
	return -1

func swap_slots(slot_a: int, slot_b: int):
	if slot_a < 0 or slot_b < 0 or slot_a >= slots_count or slot_b >= slots_count:
		return
	
	if equipped_slot == slot_a:
		equipped_slot = slot_b
	elif equipped_slot == slot_b:
		equipped_slot = slot_a
	
	var temp_item = slots[slot_a]
	var temp_quantity = quantities[slot_a]
	
	slots[slot_a] = slots[slot_b]
	quantities[slot_a] = quantities[slot_b]
	
	slots[slot_b] = temp_item
	quantities[slot_b] = temp_quantity
	
	inventory_updated.emit()
