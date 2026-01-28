extends Resource
class_name WagonPool

@export var wagons: Array[WagonEntry] = []

func pick_random() -> WagonData:
	if wagons.is_empty():
		return null

	var total_weight: int = 0
	for entry in wagons:
		total_weight += entry.weight

	var random_value = randi_range(0, total_weight - 1)
	
	var current_weight: int = 0
	for entry in wagons:
		current_weight += entry.weight
		if random_value < current_weight:
			return entry.wagon_data
			
	return null # Should not happen
