extends Node3D

#####################
# EXPORT PARAMS
#####################
# movement params
@export_range(0, 1000) var movement_speed: float = 15
@export_range(0, 1000) var camera_bounds_margin: int = 100
# rotation params
@export_range(0, 90) var min_elevation_angle: int = 10
@export_range(0, 90) var max_elevation_angle: int = 90
@export_range(0, 1000, 0.1) var rotation_speed: float = 100.0
# zoom
@export_range(0, 1000) var min_zoom: int = 5
@export_range(0, 1000) var max_zoom: int = 20
@export_range(0, 1000, 0.1) var zoom_speed: float = 50
@export_range(0, 1000, 0.1) var zoom_speed_damp: float = 0.5
#edge
@export_range(0, 1000) var edge_margin: float = 50
@export_range(0, 10, 0.5) var edge_speed: float = 3
#pan
@export_range(0, 10, 0.01) var pan_speed: float = 2
# flags
@export var allow_rotation: bool = true
@export var inverted_y: bool = false
@export var zoom_to_cursor: bool = true

@onready var player: Node3D = get_owner()

#####################
# PARAMS
#####################
# movement
var _last_mouse_position = Vector2()
var _is_rotating = false
@onready var Elevation: Node3D = $Elevation
# zoom
@onready var Camera: Camera3D = $Elevation/Camera3D
const GROUND_PLANE = Plane(Vector3.UP, 0)
const RAY_LENGTH = 1000
@onready var _camera_pivot: Node3D = self
var mouse_input = 0.0


#####################
# OVERRIDE FUNCTIONS
#####################

func _process(delta) -> void:
	_edge_move(delta)
	_move(delta)
	_rotate(delta)
	_zoom_controller(delta)
	
func _unhandled_input(event: InputEvent) -> void:
	# test if we are rotating
	if event.is_action_pressed("camera_rotate"):
		_is_rotating = true
		_last_mouse_position = get_viewport().get_mouse_position()
	if event.is_action_released("camera_rotate"):
		_is_rotating = false


#####################
# MOVEMENT FUNCTIONS
#####################
func _move(delta: float) -> void:
	# initialize a velocity vector
	var velocity = Vector3()

	if Input.is_action_pressed("camera_left"):
		player.rotate_y(deg_to_rad(-rotation_speed * delta))
	if Input.is_action_pressed("camera_right"):
		player.rotate_y(deg_to_rad(rotation_speed * delta))
	# normalize and clamp speed
	velocity = velocity.normalized()
	# translate
	global_translate(velocity * delta * movement_speed)
	
	position = position.clamp(
		Vector3(float(camera_bounds_margin), float(max_zoom), float(camera_bounds_margin)) * -1,
		Vector3(float(camera_bounds_margin), float(max_zoom), float(camera_bounds_margin))
		)

func _rotate(delta: float) -> void:
	if !_is_rotating || !allow_rotation:
		return
	# calculate mouse movement
	var displacement = _get_mouse_displacement()
	# use horizontal displacement to rotate
	_rotate_left_right(delta, displacement.x)
	# use the vertical displacement to elevate
	_elevate(delta, displacement.y)
	
func _edge_move(delta: float) -> void:
	# initialize a velocity vector
	var velocity = Vector3()
	var viewport = get_viewport()
	var visible_rect = viewport.get_visible_rect()
	# get mouse position
	var m_pos = viewport.get_mouse_position()
	# populate it
	if m_pos.x < edge_margin:
		player.rotate_y(deg_to_rad(-rotation_speed * delta))
	elif m_pos.x > visible_rect.size.x - edge_margin:
		player.rotate_y(deg_to_rad(rotation_speed * delta))
	if m_pos.y < edge_margin:
		mouse_input += 1 * delta
	elif m_pos.y > visible_rect.size.y - edge_margin:
		mouse_input -= 1 * delta
	else:
		mouse_input = 0.0
		
	global_translate(velocity.rotated(Vector3(0, 1, 0), rotation.y))


func _zoom_controller(_delta: float) -> void:
	if (Input.is_action_just_pressed("scrollUp") or Input.is_action_pressed("camera_backward")):
		mouse_input += 1.0
	if (Input.is_action_just_pressed("scrollDown") or Input.is_action_pressed("camera_forward")):
		mouse_input -= 1.0

	if mouse_input != 0.0:
		_camera_pivot.scale.x += mouse_input * 0.1
		_camera_pivot.scale.y += mouse_input * 0.1
		_camera_pivot.scale.z += mouse_input * 0.1
	# Prevent the camera from zooming too far in or out.
	_camera_pivot.scale.x = clampf(_camera_pivot.scale.x, 0.5, 4.0)
	_camera_pivot.scale.y = clampf(_camera_pivot.scale.y, 0.5, 4.0)
	_camera_pivot.scale.z = clampf(_camera_pivot.scale.z, 0.5, 4.0)


#####################
# HELPER FUNCTIONS
#####################
func _get_mouse_displacement() -> Vector2:
	var current_mouse_position = get_viewport().get_mouse_position()
	var displacement = current_mouse_position - _last_mouse_position
	_last_mouse_position = current_mouse_position
	return displacement

func _rotate_left_right(delta: float, val: float) -> void:
	rotation.y += deg_to_rad(val * delta * rotation_speed) * -1

func _elevate(delta: float, val: float) -> void:
	# calculate new elevation
	var new_elevation = rad_to_deg(Elevation.rotation.x)
	if inverted_y:
		new_elevation += val * delta * rotation_speed
	else:
		new_elevation -= val * delta * rotation_speed
	# clamp the new elevation
	new_elevation = clamp(
		new_elevation,
		- max_elevation_angle,
		- min_elevation_angle
		)
	Elevation.rotation.x = deg_to_rad(new_elevation)
