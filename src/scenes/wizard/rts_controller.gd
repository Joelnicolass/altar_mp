extends Node3D

# --- MOVEMENT PARAMS --- #
@export_range(0, 1000) var movement_speed: float = 15
@export_range(0, 1000) var camera_bounds_margin: int = 100
# --- ROTATION PARAMS --- #
@export_range(0, 1000, 0.1) var rotation_speed: float = 100.0
# --- ZOOM PARAMS --- #
@export_range(0, 1000) var min_zoom: float = 0.5
@export_range(0, 1000) var max_zoom: float = 5.0
@export_range(0, 1000, 0.1) var zoom_speed: float = 1.0
# --- EDGE SCROLLING PARAMS --- #
@export_range(0, 1000) var edge_margin: float = 50
@export_range(0, 10, 0.5) var edge_speed: float = 3

# --- CAMERA PROPERTIES --- #
@onready var player: Node3D = get_parent().get_parent()
@onready var _camera_pivot: Node3D = self
@export var camera_follow_speed: float = 5.0

const GROUND_PLANE = Plane(Vector3.UP, 0)
const RAY_LENGTH = 1000
var mouse_input = 0.0


func _process(delta) -> void:
	if not player.is_multiplayer_authority(): return

	_follow_player(delta)
	_edge_move_controller(delta)
	_move_controller(delta)
	_zoom_controller(delta)


func _follow_player(_delta: float) -> void:
	_camera_pivot.global_transform.origin = player.global_transform.origin

	
func _move_controller(delta: float) -> void:
	var velocity = Vector3()

	if Input.is_action_pressed("camera_left"):
		#player.rotate_y(deg_to_rad(rotation_speed * delta))
		#_align_with_quaternion(delta)
		# interpolacion simple - no funciona por el euler
		#_camera_pivot.global_rotation = lerp(_camera_pivot.global_rotation, player.global_rotation, 0.05)
		# Segunda opcion para el manejo de la camara
		rotate_y(deg_to_rad(rotation_speed * delta))
	if Input.is_action_pressed("camera_right"):
		#player.rotate_y(deg_to_rad(-rotation_speed * delta))
		#_align_with_quaternion(delta)
		rotate_y(deg_to_rad(-rotation_speed * delta))

	velocity = velocity.normalized()
	global_translate(velocity * delta * movement_speed)
	

func _edge_move_controller(delta: float) -> void:
	var velocity = Vector3()
	var viewport = get_viewport()
	var visible_rect = viewport.get_visible_rect()
	var m_pos = viewport.get_mouse_position()

	if m_pos.x < edge_margin:
		#player.rotate_y(deg_to_rad(rotation_speed * delta))
		# mover la camara a la izquierda sobre el eje de la camara
		rotate_y(deg_to_rad(rotation_speed * delta))
		
	elif m_pos.x > visible_rect.size.x - edge_margin:
		#player.rotate_y(deg_to_rad(-rotation_speed * delta))
		# mover la camara a la derecha sobre el eje de la camara
		rotate_y(deg_to_rad(-rotation_speed * delta))
		
	if m_pos.y < edge_margin:
		mouse_input -= zoom_speed * delta
	elif m_pos.y > visible_rect.size.y - edge_margin:
		mouse_input += zoom_speed * delta
	else:
		mouse_input = 0.0
		
	global_translate(velocity.rotated(Vector3(0, 1, 0), rotation.y))


func _zoom_controller(_delta: float) -> void:
	if (Input.is_action_just_pressed("scroll_up") or Input.is_action_pressed("camera_backward")):
		mouse_input += zoom_speed
	if (Input.is_action_just_pressed("scroll_down") or Input.is_action_pressed("camera_forward")):
		mouse_input -= zoom_speed

	if mouse_input != 0.0:
		_camera_pivot.scale.x += mouse_input * 0.1
		_camera_pivot.scale.y += mouse_input * 0.1
		_camera_pivot.scale.z += mouse_input * 0.1
	# Prevent the camera from zooming too far in or out.
	_camera_pivot.scale.x = clampf(_camera_pivot.scale.x, min_zoom, max_zoom)
	_camera_pivot.scale.y = clampf(_camera_pivot.scale.y, min_zoom, max_zoom)
	_camera_pivot.scale.z = clampf(_camera_pivot.scale.z, min_zoom, max_zoom)


func _align_with_quaternion(delta: float) -> void:
	var old_scale: Vector3 = _camera_pivot.global_transform.basis.get_scale()

	var cur_q: Quaternion = _camera_pivot.global_transform.basis.get_rotation_quaternion()
	var tgt_q: Quaternion = player.global_transform.basis.get_rotation_quaternion()
	var t: float = clamp(camera_follow_speed * delta, 0.0, 1.0)
	var new_q: Quaternion = cur_q.slerp(tgt_q, t)
	var new_bas: Basis = Basis(new_q).orthonormalized()

	var scaled_bas: Basis = new_bas.scaled(old_scale)

	var xform: Transform3D = _camera_pivot.global_transform
	xform.basis = scaled_bas
	_camera_pivot.global_transform = xform
