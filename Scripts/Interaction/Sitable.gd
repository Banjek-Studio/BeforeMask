extends Interactable
class_name Sitable

signal try_to_sit

func interact():
	try_to_sit.emit()
