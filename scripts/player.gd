extends CharacterBody3D

@export var toBeMonitored : Dictionary

var isMoving : bool = false
var mvmtKeysPressed : int = 0

@export_category("Características")
@export var SPEED : float = 10.0
@export var RUN_MULTIPLIER : float = 2
@export var JUMP_VELOCITY : float = 6.5

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
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)	

	velocity = velocity.rotated(Vector3(0, 1, 0), $Camera/horizontalRotation.rotation.y)
	$Mesh.rotation = Vector3(0,$Camera/horizontalRotation.rotation.y,0) + Vector3(0, asin(-direction.x), 0)
	print(direction)
	move_and_slide()
	
	# DEBUG
	set_monitor_values()

func _while_idle(delta):
	isMoving = false
	if mvmtKeysPressed > 0:
		%StateMachine.send_event("walking")

func _while_walking(delta):
	if mvmtKeysPressed == 0:
		%StateMachine.send_event("idle")

func _while_running(delta):
	if mvmtKeysPressed == 0:
		%StateMachine.send_event("idle")
	
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
	toBeMonitored["playermesh-x"] = $Mesh.rotation_degrees.x
	toBeMonitored["playermesh-y"] = $Mesh.rotation_degrees.y
	toBeMonitored["camara-root-y"] = %Camera.rotation_degrees.y

	%VariablesMonitor.args = toBeMonitored


func _on_start_moving():
	isMoving = true
	
	#self.rotation_degrees.y += %Camera.get_rotation_degrees_y()
	#%Camera.yaw = self.rotation_degrees.y
	#if abs(%Camera.yaw) > 180:
		#%Camera.yaw -= 360 * sign(%Camera.yaw)
	#%Camera.set_rotation_degrees_y(0)
	#%Camera.omitOneFrame = true
	
	if Input.is_action_pressed("run"):
		%StateMachine.send_event("running")

func _on_stop_moving():
	#%Camera.yaw = 0
	#%Camera.omitOneFrame = true
	pass
