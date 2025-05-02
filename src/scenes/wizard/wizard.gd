class_name Wizard extends CharacterBody3D

# --- WIZARD PROPERTIES --- #
@export var max_health: int = 100
@export var max_mana: int = 200
@export var speed: float = 6.0
@export var run_speed: float = 16.0
@export var rotation_speed: float = 100.0

var current_health: int
var current_mana: int
var souls: int = 0


# --- COMMON PROPERTIES --- #
var initial_transform: Transform3D

# --- CAMERA PROPERTIES --- #
@onready var _camera := $Camera/RTSController/Elevation/Camera3D as Camera3D

# --- MOVEMENT PROPERTIES --- #
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- SELECTION BOX --- #
@onready var selection_box: Node2D = $SelectionBox

func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	print("Player " + str(name) + " has authority: " + str(is_multiplayer_authority()))


func _ready() -> void:
	if not is_multiplayer_authority(): return

	selection_box.is_authority = true
	selection_box.camera = _camera
	global_transform = initial_transform
	_camera.current = true


func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return

	_apply_gravity(delta)
	_input_handler(delta)
	move_and_slide()


# --- HELPERS FUNCTIONS --- #
# TODO! esto tiene que manejar el servidor
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

# TODO! esto tiene que manejar el servidor
func _input_handler(delta: float) -> void:
	var _speed = speed
	if Input.is_action_pressed("run"):
		_speed = run_speed

	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		direction += -transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z

	if Input.is_action_pressed("move_left"):
		# TODO: asignar tecla para este tipo de movimiento
		if Input.is_action_pressed("ui_home"):
			direction += -transform.basis.x
		else:
			# tank movement
			rotate_y(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("move_right"):
		# TODO: asignar tecla para este tipo de movimiento
		if Input.is_action_pressed("ui_home"):
			direction += transform.basis.x
		else:
			# tank movement
			rotate_y(deg_to_rad(-rotation_speed * delta))
		
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * _speed
		velocity.z = direction.z * _speed
	else:
		velocity.x = 0
		velocity.z = 0
	
# --- NETWORK FUNCTIONS --- #
