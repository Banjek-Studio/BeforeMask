extends ItemData
class_name Battery

@export var max_capability: float = 100.0
@export var capability: float = 100.0

func use(inventory: Inventory, slot_index: int) -> bool:
	if inventory.equipped_item == null:
		return false
	
	var tree = inventory.get_tree()
	var nodes_in_group = tree.get_nodes_in_group("equipped_item")

	if nodes_in_group.is_empty():
		return false

	var flashlight_node = nodes_in_group[0] as FlashlightItem
	if not flashlight_node:
		return false

	if flashlight_node.battery and flashlight_node.battery.capability >= flashlight_node.battery.max_capability:
		return false

	var old_battery: Battery = flashlight_node.battery
	
	inventory.remove_item(slot_index, 1)
	flashlight_node.battery = self
	
	if old_battery and old_battery.capability > 0:
		inventory.add_item(old_battery)
	
	flashlight_node._update_energy_visuals()
	return true
