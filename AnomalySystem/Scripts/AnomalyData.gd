extends Resource
class_name AnomalyData

## The type of this anomaly. Must match the enum in WagonData.
@export var anomaly_type: WagonData.AnomalyType

## Name for debugging and UI purposes.
@export var anomaly_name: String = "Unnamed Anomaly"

## A brief description of what the anomaly does.
@export_multiline var description: String = ""

## How long the anomaly effect should last in seconds. 0 means infinite.
@export var duration: float = 0.0

## Sound effect to play on activation.
@export var activation_sound: AudioStream
