extends Control
class_name InventoryUI

@export var slot_scene: PackedScene
@export var slots_container: GridContainer 
@onready var item_info: VBoxContainer = %ItemDisplay
@onready var item_name_label: Label = item_info.get_node("ItemName")
@onready var item_description_label: Label = item_info.get_node("ItemDescription")
@onready var drop_button: Button = item_info.get_node("DropButton")
@onready var equip_button: Button = item_info.get_node("EquipButton")
@onready var item_viewport: SubViewport = %InventoryItemViewport

var inventory: Inventory
var current_3d_item: Node3D = null
var selected_slot: int = -1
var slot_instances: Array[InventorySlot] = []

func _ready():
	hide_inventory()

func setup(inv: Inventory):
	inventory = inv
	inventory.inventory_updated.connect(_on_inventory_updated)
	inventory.item_equipped.connect(_on_item_equipped)
	inventory.item_unequipped.connect(_on_item_unequipped)
	
	_create_slots()
	_setup_hotkeys()

func _create_slots():
	# Clear existing slots
	for child in slots_container.get_children():
		child.free()
		
	slot_instances.clear()
	# Create new slots based on inventory size
	for i in range(inventory.slots_count):
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.slot_clicked.connect(_on_slot_clicked)
		slots_container.add_child(slot)
		slot_instances.append(slot)
	
	call_deferred("_on_inventory_updated")

func _setup_hotkeys():
	# Create input actions for hotkeys
	for i in range(min(inventory.slots_count, 9)): # Support up to 9 hotkeys
		var action_name = "hotkey_%d" % (i + 1)
		if not InputMap.has_action(action_name):
			var event = InputEventKey.new()
			event.keycode = KEY_1 + i
			InputMap.add_action(action_name)
			InputMap.action_add_event(action_name, event)

func _on_inventory_updated():
	for i in range(slot_instances.size()):
		var slot = slot_instances[i]
		if slot:
			var item_data = inventory.get_item_at(i)
			var quantity = inventory.get_quantity_at(i)
			slot.update_slot(item_data, quantity)
			
			# Update equipped highlight
			slot.set_equipped(i == inventory.equipped_slot)

func _on_slot_clicked(slot_index: int, button: int):
	if button == MOUSE_BUTTON_LEFT:
		_select_slot(slot_index)
	elif button == MOUSE_BUTTON_RIGHT:
		_use_context_menu(slot_index)
		#_update_3d_display()

func _select_slot(slot_index: int):
	if selected_slot != -1 and selected_slot < slot_instances.size():
		slot_instances[selected_slot].set_highlight_click(false)
	
	selected_slot = slot_index
	if selected_slot < slot_instances.size():
		slot_instances[selected_slot].set_highlight_click(true)
	
	var item_data = inventory.get_item_at(slot_index)
	_update_item_info(item_data)

func _use_context_menu(slot_index: int):
	var item_data = inventory.get_item_at(slot_index)
	if item_data:
		# You can implement a context menu here
		print("Right-clicked on slot ", slot_index, " with item ", item_data.name)

func _update_item_info(item_data: ItemData) -> void:
	if item_data:
		item_name_label.text = item_data.name
		item_description_label.text = item_data.description
		drop_button.disabled = false
		equip_button.disabled = false
		equip_button.text = "Equip" if inventory.equipped_slot != selected_slot else "Unequip"
	else:
		item_name_label.text = ""
		item_description_label.text = ""
		drop_button.disabled = true
		equip_button.disabled = true

func _on_item_equipped(item_data: ItemData, slot_index: int):
	if slot_index < slot_instances.size():
		slot_instances[slot_index].set_equipped(true)
	_update_item_info(item_data)
	print("Equipped: ", item_data.name)

func _on_item_unequipped(item_data: ItemData, unequipped_slot: int = -1):
	# Update all slots to remove equipped highlight
	for i in range(slot_instances.size()):
		slot_instances[i].set_equipped(false)
	
	if unequipped_slot != -1:
		var current_item = inventory.get_item_at(unequipped_slot)
		_update_item_info(current_item)
	print("Unequipped: ", item_data.name)

func _update_3d_display(slot_index: int = selected_slot):
	# Clear current 3D item
	if current_3d_item:
		current_3d_item.queue_free()
		current_3d_item = null
	
	if slot_index == -1:
		return
	
	var item_data = inventory.get_item_at(slot_index)
	if item_data and item_data.scene_3d:
		current_3d_item = item_data.scene_3d.instantiate()
		item_viewport.add_child(current_3d_item)
		
		# Position and scale the item
		current_3d_item.scale = Vector3.ONE * item_data.scale_in_inventory


func show_inventory():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func hide_inventory():
	if selected_slot != -1 and selected_slot < slot_instances.size():
		slot_instances[selected_slot].set_highlight_click(false)
	_update_item_info(null)
	selected_slot = -1
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event.is_action_pressed("inventory"):
		if visible:
			hide_inventory()
		else:
			show_inventory()
	if event.is_action_pressed("ui_cancel") and visible:
		hide_inventory()
	
	for i in range(min(inventory.slots_count, 9)):
		if event.is_action_pressed("hotkey_%d" % (i + 1)):
			_handle_hotkey(i)

func _handle_hotkey(slot_index: int):
	if slot_index < inventory.slots_count:
		inventory.toggle_equip_item(slot_index)

func _on_close_button_pressed() -> void:
	hide_inventory()

func _on_equip_button_pressed() -> void:
	if selected_slot != -1:
		inventory.toggle_equip_item(selected_slot)

func _on_drop_button_pressed() -> void:
	if selected_slot != -1:
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			var camera = player.get_node("Head/HeadBob/Camera3D") as Camera3D
			var look_direction = -camera.global_transform.basis.z
			var throw_position = camera.global_position + look_direction * 1.5
			player.drop_equipped_item(throw_position, look_direction, selected_slot)
			_update_item_info(inventory.get_item_at(selected_slot))

func _on_use_button_pressed() -> void:
	if selected_slot != -1:
		var item_data = inventory.get_item_at(selected_slot)
		if item_data and item_data.has_method("use"):
			inventory.use_item(selected_slot)
