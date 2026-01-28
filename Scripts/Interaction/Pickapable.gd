extends Interactable
class_name Pickable

signal item_picked_up

func interact():
	item_picked_up.emit() 
