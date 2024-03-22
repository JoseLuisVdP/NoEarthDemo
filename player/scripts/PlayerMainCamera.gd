extends Node3D

@onready var _camera = $horizontalRotation/SpringArm/Camera
@onready var _springarm = $horizontalRotation/SpringArm
@onready var _horizontal = $horizontalRotation

var _yaw : float = 0
var _pitch : float = 0
var max_fov : int = 75
var min_fov : int = 20

@export_category("Parámetros")
@export var h_sensibility : int = 100
@export var v_sensibility : int = 100
@export var inverted_h : bool = false
@export var inverted_v : bool = false
@export var max_pitch : int = 80
@export var min_pitch : int = -90

func _ready():
	pass

func _process(delta):
	pass

func _unhandled_input(event):
	if event.is_action_pressed("camera_toggle"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_released("camera_toggle") || event.is_action_released("inventory"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action("zoomin") && _camera.fov > min_fov:
		_camera.fov -= 2
	if event.is_action("zoomout") && _camera.fov < max_fov:
		_camera.fov += 2

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && event is InputEventMouseMotion:
		_yaw -= event.relative.x * v_sensibility / 10000
		_pitch -= event.relative.y * h_sensibility / 10000
		
		_pitch = clamp(_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _physics_process(delta):
		_horizontal.rotation.y = lerp_angle(_horizontal.rotation.y, _yaw, ease(h_sensibility * delta / 5, -2))
		_springarm.rotation.x = lerp_angle(_springarm.rotation.x, _pitch, ease(v_sensibility * delta / 5, -2))
		_springarm.rotation.x = clamp(_springarm.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func get_rotation_degrees_x():
	return _springarm.rotation_degrees.x
	
func get_rotation_degrees_y():
	return _horizontal.rotation_degrees.y

func get_rotation_degrees_z():
	return _camera.rotation_degrees.z
	
func get_rotation_x():
	return _springarm.rotation.x
	
func get_rotation_y():
	return _horizontal.rotation.y

func get_rotation_z():
	return _camera.rotation.z
