class_name Wizard extends CharacterBody3D

var initial_transform: Transform3D

# --- WIZARD PROPERTIES --- #
@export var max_health: int = 100
@export var max_mana: int = 200
@export var speed: float = 6.0

var current_health: int
var current_mana: int
var souls: int = 0

# --- CAMERA PROPERTIES --- #
@onready var _camera := $RTSController/Elevation/Camera3D as Camera3D

# --- MOVEMENT PROPERTIES --- #
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	print("Player " + str(name) + " has authority: " + str(is_multiplayer_authority()))


func _ready() -> void:
	if not is_multiplayer_authority(): return

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
func _input_handler(_delta: float) -> void:
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		direction += -transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	
	if direction != Vector3.ZERO:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
	
# --- NETWORK FUNCTIONS --- #
