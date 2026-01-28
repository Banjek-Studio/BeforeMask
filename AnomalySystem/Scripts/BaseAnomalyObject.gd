extends Node3D
class_name BaseAnomalyObject

## **ВАЖЛИВО:** Встановіть цей тип в інспекторі для кожної аномалії.
## Він має відповідати типу в AnomalyData та WagonData.
@export var type: WagonData.AnomalyType

var parent_wagon: Wagon
var is_active: bool = false

# Ця функція викликається один раз вагоном для налаштування
func initialize(wagon: Wagon):
	self.parent_wagon = wagon

# Ця функція викликається, коли аномалія має стати активною.
# Нащадки повинні розширювати цю функцію своєю логікою.
func activate():
	if is_active: return
	is_active = true
	show() # За замовчуванням робимо об'єкт видимим
	#print("Anomaly '%s' activated in Wagon %d." % [WagonData.AnomalyType.keys()[type], parent_wagon.wagon_number])

# Ця функція викликається, щоб вимкнути аномалію.
# Нащадки повинні розширювати цю функцію своєю логікою.
func deactivate():
	if not is_active: return
	is_active = false
	hide() # За замовчуванням ховаємо об'єкт
	#print("Anomaly '%s' deactivated in Wagon %d." % [WagonData.AnomalyType.keys()[type], parent_wagon.wagon_number])
