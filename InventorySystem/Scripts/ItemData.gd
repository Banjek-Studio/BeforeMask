extends Resource
class_name ItemData

@export_group("Basic Properties")
@export var item_id: int 
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D = preload("res://icon.svg")
@export var max_stack_size: int = 1

@export_group("3D Display")
@export var scale_in_inventory: float = 1.0
@export var item_scale: Vector3 = Vector3.ONE

@export_group("Item Type")
enum ItemType { CONSUMABLE, WEAPON, KEY_ITEM, MATERIAL, CURRENCY, LIGHT_SOURCE, EQUIPMENT }
@export var item_type: ItemType

@export_group("Trade Properties")
@export var base_price: int = 0
@export var can_be_traded: bool = true
@export var trade_target: String = "" 

@export_group("Save Properties")
@export var is_save_point: bool = false
@export var respawn_on_use: bool = false

@export_group("Equipment Properties")
@export var equipment_slot: String = ""  # "none" for non-equipable items
@export var filter_effect: String = ""  # "black" for goggles
@export var anomaly_detection: bool = false
@export var anomaly_protection: bool = false
@export var uses_remaining: int = 0

@export_group("Quest Properties")
@export var is_quest_item: bool = false
@export var quest_target: String = ""  # "guide" for tickets, etc.



func use(_inventory: Inventory, _slot_index: int) -> bool:
	return false

func set_item_data(data: ItemData) -> void:
	item_id = data.item_id
	name = data.name
	description = data.description
	icon = data.icon
	max_stack_size = data.max_stack_size
	item_type = data.item_type
