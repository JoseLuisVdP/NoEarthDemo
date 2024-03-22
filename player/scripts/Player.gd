extends CharacterBody3D

@onready var _mesh = $Mesh
@onready var ui = %UI

@export var toBeMonitored : Dictionary

var isMoving : bool = false
var mvmtKeysPressed : int = 0
var meshRotation : float
var direction
var inventory:Inventory = Inventory.new()
# Tipo de dato correcto?
var pickable_objects:Array[Node3D] = []

signal can_pickup_item(item:Item)
signal can_not_pickup_item(item:Item)

@export_category("Características")
@export var SPEED : float = 10.0
@export var RUN_MULTIPLIER : float = 2
@export var JUMP_VELOCITY : float = 6.5
@export var PUSH_FORCE : float
@export var WEIGHT : float

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
	if event.is_action_pressed("inventory"):
		ui.open_inventory(inventory)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "up", "down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)	

	velocity = velocity.rotated(Vector3(0, 1, 0), %Camera.get_rotation_y())
	move_and_slide()
	
	#Manejar colisiones
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			c.get_collider().apply_central_impulse(-c.get_normal() * PUSH_FORCE * WEIGHT / 5)
	
	# DEBUG
	set_monitor_values()

func _while_idle(delta):
	isMoving = false
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
	SPEED *= RUN_MULTIPLIER
	if !Input.is_action_pressed("run"):
		%StateMachine.send_event("walking")
	
func _on_stop_running():
	SPEED /= RUN_MULTIPLIER

func set_monitor_values():
	toBeMonitored["velocidad-x"] = velocity.x
	toBeMonitored["velocidad-y"] = velocity.y
	toBeMonitored["velocidad-z"] = velocity.z
	toBeMonitored["camara-x"] = %Camera.get_rotation_degrees_x()
	toBeMonitored["camara-y"] = %Camera.get_rotation_degrees_y()
	toBeMonitored["playermesh-x"] = _mesh.rotation_degrees.x
	toBeMonitored["playermesh-y"] = _mesh.rotation_degrees.y
	toBeMonitored["Pickable items"] = str(pickable_objects)
	%VariablesMonitor.args = toBeMonitored

func _on_start_moving():
	isMoving = true
	if Input.is_action_pressed("run"):
		%StateMachine.send_event("running")

func _on_stop_moving():
	pass

func change_direction():
	meshRotation = %Camera.get_rotation_y() + (PI if direction.z > 0 else 0) + asin(-direction.x) * sign(-direction.z+0.5)
	_mesh.rotation.y = lerp_angle(_mesh.rotation.y, meshRotation, ease(0.5, -2))

func _on_interact_area_body_entered(body):
	print("_entered - " + str(body))
	
	if body.is_in_group("pickups"):
		print("Puedo pillar " + body.get_parent().item.name)
		pickable_objects.append(body.get_parent())
		emit_signal("can_pickup_item", body.get_parent().item)

func pickup_item(item):
	print("He pillado " + item.name)
	inventory.add_item(item)
	emit_signal("can_not_pickup_item", item)

func _on_interact_area_body_exited(body):
	if body.is_in_group("pickups"):
		print("_exited - " + str(body))
		pickable_objects.erase(body.get_parent())
		emit_signal("can_not_pickup_item", body.get_parent().item)

func _on_picking_up_an_item_state_exited():
	var body = pickable_objects.pop_front()
	if body == null: return
	pickup_item(body.item)
	emit_signal("can_not_pickup_item", body.item)
	body.queue_free()
