extends Node3D
class_name WagonConnector
signal player_entered(connector: WagonConnector)

var wagon_before: Wagon
var wagon_after: Wagon

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_entered.emit(self)

func set_wagon_before(wagon: Wagon) -> void:
	wagon_before = wagon

func set_wagon_after(wagon: Wagon) -> void:
	wagon_after = wagon

func get_wagon_before() -> Wagon:
	return wagon_before
	
func get_wagon_after() -> Wagon:
	return wagon_after
