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


func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())
	print("Player " + str(name) + " has authority: " + str(is_multiplayer_authority()))


func _ready() -> void:
	if not is_multiplayer_authority(): return

	global_transform = initial_transform
	_camera.current = true


func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return

	if Input.is_action_pressed("ui_right"):
		translate(Vector3(0.1, 0, 0))
	if Input.is_action_pressed("ui_left"):
		translate(Vector3(-0.1, 0, 0))
	if Input.is_action_pressed("ui_up"):
		translate(Vector3(0, 0, -0.1))
	if Input.is_action_pressed("ui_down"):
		translate(Vector3(0, 0, 0.1))
