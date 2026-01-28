extends Node

@export var item_scenes: Dictionary[int, PackedScene] = { 
	1: preload("res://InventorySystem/Scenes/Items/flash_light.tscn"),
	2: preload("res://InventorySystem/Scenes/Items/battery.tscn") 
}
