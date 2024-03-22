extends RigidBody3D
class_name Player

@onready var _mesh : MeshInstance3D = $Mesh
@onready var _ui : CanvasLayer = $"../../UI"

@export var toBeMonitored : Dictionary

var mvmtKeysPressed : int = 0
var meshRotation : float
var input_dir : Vector2
var inventory:Inventory = Inventory.new()
# Tipo de dato correcto?
var pickable_objects:Array[Node3D] = []

signal can_pickup_item(item:Item)
signal can_not_pickup_item(item:Item)

@export_category("Características")
@export var speed : float = 10.0
@export var RUN_MULTIPLIER : float = 2
@export var JUMP_VELOCITY : float = 30

var _pid := Pid3D.new(12 * mass, .03 * mass, 0.3 * mass)

func _ready():
	Input.set_default_cursor_shape(Input.CURSOR_CROSS)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _unhandled_input(event):
	if event.is_action_pressed("run"):
		%StateMachine.send_event("running")
	if event.is_action_released("run"):
		%StateMachine.send_event("walking")
	if event.is_action_pressed("up") || event.is_action_pressed("down") || event.is_action_pressed("left") || event.is_action_pressed("right"):
		mvmtKeysPressed += 1
	if event.is_action_released("up") || event.is_action_released("down") || event.is_action_released("left") || event.is_action_released("right"):
		mvmtKeysPressed -= 1
	if event.is_action_pressed("interact"):
		if pickable_objects.size() > 0:
			%StateMachine.send_event("pickingUpAnItem")
	if event.is_action_released("inventory"):
		_ui.inventory(inventory)


func _physics_process(delta):
	input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	var target_velocity = Vector3(input_dir.x, 0, input_dir.y) * speed
	target_velocity = target_velocity.rotated(Vector3.UP, %Camera.get_rotation_y())
	var velocity_error = target_velocity - linear_velocity
	velocity_error.y = 0
	var correction_force = 0
	if is_on_floor():
		correction_force = _pid.update(velocity_error, delta)
		if Input.is_action_just_pressed("jump"):
			apply_central_force(-get_gravity() * JUMP_VELOCITY * mass)
	else:
		correction_force = _pid.update_jumping(velocity_error, delta)
	if linear_velocity.length() < 0.1: linear_velocity = Vector3.ZERO
	apply_central_force(correction_force)
	
	# DEBUG
	set_monitor_values()
	
func _while_idle(delta):
	if mvmtKeysPressed > 0:
		%StateMachine.send_event("walking")

func _while_walking(delta):
	if mvmtKeysPressed == 0:
		%StateMachine.send_event("idle")
	change_direction()

func _while_running(delta):
	if mvmtKeysPressed == 0:
		%StateMachine.send_event("idle")
	change_direction()
	
func _on_start_running():
	speed *= RUN_MULTIPLIER
	if !Input.is_action_pressed("run"):
		%StateMachine.send_event("walking")
	
func _on_stop_running():
	speed /= RUN_MULTIPLIER

func set_monitor_values():
	toBeMonitored["velocidad-x"] = linear_velocity.x
	toBeMonitored["velocidad-y"] = linear_velocity.y
	toBeMonitored["velocidad-z"] = linear_velocity.z
	toBeMonitored["camara-x"] = %Camera.get_rotation_degrees_x()
	toBeMonitored["camara-y"] = %Camera.get_rotation_degrees_y()
	toBeMonitored["playermesh-x"] = _mesh.rotation_degrees.x
	toBeMonitored["playermesh-y"] = _mesh.rotation_degrees.y
	toBeMonitored["Pickable items"] = str(pickable_objects)
	%VariablesMonitor.args = toBeMonitored

func _on_start_moving():
	if Input.is_action_pressed("run"):
		%StateMachine.send_event("running")

func _on_stop_moving():
	pass

func change_direction():
	meshRotation = %Camera.get_rotation_y() + (PI if input_dir.y > 0 else 0) + asin(-input_dir.x) * sign(-input_dir.y+0.5)
	_mesh.rotation.y = lerp_angle(_mesh.rotation.y, meshRotation, ease(0.5, -2))

func pickup_item(item):
	print("He pillado " + item.name)
	inventory.add_item(item)

func _on_picking_up_an_item_state_exited():
	var body = pickable_objects.pop_front()
	if body == null: return
	pickup_item(body.item)
	body.queue_free()

func is_on_floor() -> bool:
	return $FloorColision.has_overlapping_bodies()

func _on_interact_area_area_entered(area):
	print("_entered - " + str(area))
	var body = area.get_parent()
	if body == null: return
	if body.is_in_group("pickups"):
		print("Puedo pillar " + body.get_parent().item.name)
		pickable_objects.append(body.get_parent())
		emit_signal("can_pickup_item", body.get_parent().item)

func _on_interact_area_area_exited(area):
	print("_exited - " + str(area))
	var body = area.get_parent()
	if body == null: return
	if body.is_in_group("pickups"):
		pickable_objects.erase(body.get_parent())
		emit_signal("can_not_pickup_item", body.get_parent().item)
