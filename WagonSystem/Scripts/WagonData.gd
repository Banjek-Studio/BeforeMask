extends Resource

class_name WagonData

@export var wagon_name: String = "Default Wagon"
@export var wagon_scene: PackedScene
@export var has_anomaly: bool = false
@export var is_lethal: bool = false
@export var anomaly : AnomalyType

enum AnomalyType {
	Shadow,
	Phantom,
	Sleep,
	Dark,
	Trap,
	False,
	Turbo,
	Bad_Doors,
	Face,
	Conductor, # Conductor
	Mirror_Glitch, # Mirror glitch
	Center_of_Attention, # Center of attention
	Cabin_Collapse, # Cabin collapse
	Knocking
}
