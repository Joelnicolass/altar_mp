class_name Wizard extends CharacterBody3D

var is_master: bool = false
var initial_transform: Transform3D

# --- WIZARD PROPERTIES --- #
@export var max_health: int = 100
@export var max_mana: int = 200
@export var speed: float = 6.0

var current_health: int
var current_mana: int
var souls: int = 0


# --- CAMERA PROPERTIES --- #

@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)

@onready var _camera_pivot := $CameraPivot as Node3D
@onready var _camera := $CameraPivot/SpringArm3D/Camera3D as Camera3D


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	print("Player " + str(name) + " has authority: " + str(is_multiplayer_authority()))


func _ready() -> void:
	if not is_master: return

	global_transform = initial_transform
	_camera.current = true


func _process(_delta: float) -> void:
	if not is_master: return

	if Input.is_action_pressed("ui_right"):
		translate(Vector3(0.1, 0, 0))
	if Input.is_action_pressed("ui_left"):
		translate(Vector3(-0.1, 0, 0))
	if Input.is_action_pressed("ui_up"):
		translate(Vector3(0, 0, -0.1))
	if Input.is_action_pressed("ui_down"):
		translate(Vector3(0, 0, 0.1))


	var mouse_input = 0.0
	if (Input.is_action_just_pressed("scrollUp")):
		mouse_input += 1.0
	if (Input.is_action_just_pressed("scrollDown")):
		mouse_input -= 1.0

	if mouse_input != 0.0:
		# zoom in/out
		_camera_pivot.scale.x += mouse_input * 0.1
		_camera_pivot.scale.y += mouse_input * 0.1
		_camera_pivot.scale.z += mouse_input * 0.1
	# Prevent the camera from zooming too far in or out.
	_camera_pivot.scale.x = clampf(_camera_pivot.scale.x, 0.5, 2.0)
	_camera_pivot.scale.y = clampf(_camera_pivot.scale.y, 0.5, 2.0)
	_camera_pivot.scale.z = clampf(_camera_pivot.scale.z, 0.5, 2.0)

			
func _unhandled_input(event: InputEvent) -> void:
	if not is_master: return

	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Prevent the camera from rotating too far up or down.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity