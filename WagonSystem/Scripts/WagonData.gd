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
	Conductor, # Провідник
	Mirror_Glitch, # Збій дзеркального викривлення
	Center_of_Attention, # Центр уваги
	Cabin_Collapse, # Розвал кабіни
	Knocking
}
