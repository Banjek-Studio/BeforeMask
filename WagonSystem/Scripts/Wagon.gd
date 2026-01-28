extends Node3D
class_name Wagon

signal player_entered_tambour(wagon: Wagon, tambour_index: int)

@export var entry_door: DoorController
@export var exit_door: DoorController
@export var entry_tambour_door: DoorController
@export var exit_tambour_door: DoorController
@export var anomalies_root: Node
@export var emergency_brake: Node3D

var wagon_number: int
var wagon_data: WagonData
var entry_connector: WagonConnector
var exit_connector: WagonConnector

func _ready() -> void:
	if emergency_brake: emergency_brake.hide()
	if entry_connector: entry_connector.set_wagon_after(self)
	if exit_connector: exit_connector.set_wagon_before(self)
	if anomalies_root:
		for anomaly in anomalies_root.get_children():
			if anomaly is BaseAnomalyObject:
				anomaly.initialize(self)

func setup(number: int, data: WagonData) -> void:
	self.wagon_number = number
	self.wagon_data = data
	name = "Wagon_%d" % number
	
	var label = find_child("Label3D", false, false)
	if label is Label3D:
		label.text = str(wagon_number)
		
	if number == 0:
		if entry_door: entry_door.unlock_and_open()

func _apply_anomaly() -> void:
	if not anomalies_root: return
	
	for child in anomalies_root.get_children():
		if child is BaseAnomalyObject:
			child.deactivate()
	
	if wagon_data and wagon_data.has_anomaly:
		var target_type = wagon_data.anomaly
		for child in anomalies_root.get_children():
			if child is BaseAnomalyObject and child.type == target_type:
				child.activate()
				print("Wagon %d is %s anomaly." % [wagon_number, WagonData.AnomalyType.keys()[target_type]])
				return # Виходимо, оскільки знайшли те, що шукали
		push_warning("Wagon #%d wanted anomaly '%s', but no matching object was found in anomalies_root." % [wagon_number, WagonData.AnomalyType.keys()[target_type]])
	else:
		print("Wagon %d is normal." % wagon_number)

func close_doors_without_locking() -> void:
	if entry_door: entry_door.close_door()
	if exit_door: exit_door.close_door()
	if entry_tambour_door: entry_tambour_door.close_door()
	if exit_tambour_door: exit_tambour_door.close_door()

# Блокує шлях, з якого гравець щойно прийшов (вихідний тамбур)
func lock_exit_path() -> void:
	if exit_tambour_door:
		exit_tambour_door.close_and_lock()

func activate_emergency_brake() -> void:
	if emergency_brake:
		emergency_brake.show()
		print("Emergency brake in Wagon %d is now active." % wagon_number)

func lock_tambour_doors() -> void:
	if entry_tambour_door: entry_tambour_door.close_and_lock()
	if exit_tambour_door: exit_tambour_door.close_and_lock()

func unlock_tambour_doors():
	if entry_tambour_door: entry_tambour_door.unlock()
	if exit_tambour_door: exit_tambour_door.unlock()

func close_and_lock_doors() -> void:
	if entry_door: entry_door.close_and_lock()
	if exit_door: exit_door.close_and_lock()
	if entry_tambour_door: entry_tambour_door.close_and_lock()
	if exit_tambour_door: exit_tambour_door.close_and_lock()

func unlock_doors() -> void:
	if entry_door: entry_door.unlock()
	if exit_door: exit_door.unlock()
	if entry_tambour_door: entry_tambour_door.unlock()
	if exit_tambour_door: exit_tambour_door.unlock()

func _on_tambour_front_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_entered_tambour.emit(self, 0)
		if entry_door:
			entry_door.unlock()

func _on_tambour_back_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player_entered_tambour.emit(self, 1)
		if exit_door:
			exit_door.unlock()
