extends Node3D

var yaw : float = 0
var pitch : float = 0
var omitOneFrame : bool = false

signal set_cam_rotation(_cam_rotation : float)

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

func _input(event):
	if event.is_action_pressed("camera_toggle"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_released("camera_toggle"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED && event is InputEventMouseMotion:
		yaw -= event.relative.x * v_sensibility / 300
		pitch -= event.relative.y * h_sensibility / 300
		
		yaw = clamp(yaw, -180, 180)
		pitch = clamp(pitch, min_pitch, max_pitch)
		
		if abs(yaw) == 180:
			yaw -= 0.0001 * yaw / 180
			yaw *= -1
			if $"..".isMoving:
				$"..".rotation_degrees.y = yaw
			else:
				$horizontalRotation.rotation_degrees.y = yaw

func _physics_process(delta):
	if omitOneFrame:
		omitOneFrame = false
	else:
		#if $"..".isMoving:
			#$"..".rotation_degrees.y = lerp($"..".rotation_degrees.y, yaw, ease(h_sensibility * delta / 5, -2))
		#else:
		#	$horizontalRotation.rotation_degrees.y = lerp($horizontalRotation.rotation_degrees.y, yaw, ease(h_sensibility * delta / 5, -2))
		$horizontalRotation.rotation_degrees.y = lerp($horizontalRotation.rotation_degrees.y, yaw, ease(h_sensibility * delta / 5, -2))
		$horizontalRotation/SpringArm.rotation_degrees.x = lerp($horizontalRotation/SpringArm.rotation_degrees.x, pitch, ease(v_sensibility * delta / 5, -2))
		$horizontalRotation/SpringArm.rotation_degrees.x = clamp($horizontalRotation/SpringArm.rotation_degrees.x, min_pitch, max_pitch)

func get_rotation_degrees_x():
	return $horizontalRotation/SpringArm.rotation_degrees.x
	
func get_rotation_degrees_y():
	return $horizontalRotation.rotation_degrees.y

func get_rotation_degrees_z():
	return $horizontalRotation/SpringArm/Camera.rotation_degrees.z

func set_rotation_degrees_y(a:float):
	$horizontalRotation.rotation_degrees.y = a
