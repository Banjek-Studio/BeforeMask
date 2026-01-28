extends Control
class_name InventorySlot

signal slot_clicked(slot_index: int, button: int)

@export var slot_index: int = 0
@export var show_quantity: bool = true
@export var show_hotkey = true

@onready var icon_texture: TextureRect = $Icon
@onready var quantity_label: Label = $Quantity
@onready var highlight: Panel = $Highlight
@onready var click_highlight: Panel = $ClickHighlight
@onready var equipped_highlight: Panel = $EquippedHighlight
@onready var hotkey_label: Label = $HotkeyLabel

func _ready() -> void:
	highlight.visible = false
	click_highlight.visible = false
	equipped_highlight.visible = false
	
	if (!show_hotkey):
		return
	
	# Show hotkey number (1-9)
	if slot_index < 9:
		hotkey_label.text = str(slot_index + 1)
	else:
		hotkey_label.visible = false

func update_slot(item_data: ItemData, quantity: int):
	if item_data:
		icon_texture.texture = item_data.icon
		icon_texture.visible = true
		if show_quantity and quantity > 1:
			quantity_label.text = str(quantity)
			quantity_label.visible = true
		else:
			quantity_label.visible = false
	else:
		icon_texture.visible = false
		quantity_label.visible = false

func set_highlight(enable: bool):
	highlight.visible = enable

func set_highlight_click(enable: bool):
	click_highlight.visible = enable

func set_equipped(enable: bool):
	equipped_highlight.visible = enable

func _on_color_rect_mouse_entered() -> void:
	set_highlight(true)


func _on_color_rect_mouse_exited() -> void:
	set_highlight(false)


func _on_color_rect_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(slot_index, event.button_index)
