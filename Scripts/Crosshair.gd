extends Control

enum CrossForm { PLUS, DOT, X, CIRCLE }

@export var cross_form: CrossForm = CrossForm.PLUS
@export var default_size : float = 1
@export var default_thickness : float = 1
@export var default_color := Color.WHITE
@export var highlight_color: Color = Color.GRAY
@export var highlight_size: float = 2
@export var highlight_thickness: float = 2

var redraw : bool = false
var is_highlighed : bool = false
var cross_size : float
var cross_thickness : float
var cross_color : Color

@onready var ray : RayCast3D = $"../Head/InteractionRayCast"

func _ready() -> void:
	cross_size = default_size
	cross_thickness = default_thickness
	cross_color = default_color

func _draw():
	var center = get_viewport_rect().size / 2
	center = center.floor()
	match cross_form:
		CrossForm.PLUS:
			draw_line(center - Vector2(cross_size, 0), center + Vector2(cross_size, 0), cross_color, cross_thickness)
			draw_line(center - Vector2(0, cross_size), center + Vector2(0, cross_size), cross_color, cross_thickness)
		CrossForm.DOT:
			draw_circle(center, cross_size, cross_color)
		CrossForm.X:
			draw_line(center - Vector2(cross_size, cross_size), center + Vector2(cross_size, cross_size), cross_color, cross_thickness)
			draw_line(center - Vector2(cross_size, -cross_size), center + Vector2(cross_size, -cross_size), cross_color, cross_thickness)
		CrossForm.CIRCLE:
			draw_arc(center, cross_size, 0, TAU, 32, cross_color, cross_thickness)

func _physics_process(_delta: float) -> void:
	if ray.is_colliding(): 
		var hit_object = ray.get_collider()
		if hit_object and hit_object.is_in_group("Interactable"):
			redraw = true
			is_highlighed = true
			_update_crosshair()
			return
		elif redraw:
			is_highlighed = false
			redraw = false
			_update_crosshair()
	elif redraw:
		is_highlighed = false
		redraw = false
		_update_crosshair()

func _update_crosshair() -> void:
	if is_highlighed:
		cross_color = highlight_color
		cross_size = highlight_size
		cross_thickness = highlight_thickness
	else:
		cross_color = default_color
		cross_size = default_size
		cross_thickness = default_thickness
	queue_redraw()
