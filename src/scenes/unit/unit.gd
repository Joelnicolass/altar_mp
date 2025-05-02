class_name Unit extends StaticBody3D

# --- COMMON PROPERTIES --- #
var initial_transform: Transform3D
var peer: int

@export var movement_speed: float = 30.0
@onready var selected = $Selected
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var map_RID: RID = get_world_3d().get_navigation_map()
@onready var raycast: RayCast3D = $RayCast3D

var is_selected = false
var pathing: bool = false
var pathing_point: int = 0
var path_points_packed: PackedVector3Array


func _enter_tree() -> void:
	set_multiplayer_authority(peer)
	print("Unit " + str(name) + "peer:" + str(peer) + " has authority: " + str(is_multiplayer_authority()))


func _ready() -> void:
	if not is_multiplayer_authority(): return


	global_transform = initial_transform

	await (get_tree().process_frame)
	_y_correction()


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if pathing:
		var path_next_point: Vector3 = path_points_packed[pathing_point] - global_position
		if path_next_point.length_squared() > 1.0:
			var velocity: Vector3 = (path_next_point.normalized() * delta) * movement_speed
			_unit_rotate_to_direction(velocity)
			global_position += velocity
		else:
			if pathing_point < (path_points_packed.size() - 1):
				pathing_point += 1
				_physics_process(delta)
			else:
				pathing = false
				pathing_point = 0


func set_is_selected(value: bool) -> void:
	if not is_multiplayer_authority(): return
	
	is_selected = value
	selected.visible = value


func move_to(movement_target: Vector3) -> void:
	if not is_multiplayer_authority(): return

	if pathing:
		pathing = false
		pathing_point = 0

	_unit_path_new(_random_position_offset(movement_target))


func _unit_rotate_to_direction(dir: Vector3) -> void:
	var forward = dir.normalized()
	
	raycast.force_raycast_update()
	if not raycast.is_colliding(): return
	var normal = raycast.get_collision_normal()
	
	var up = normal.normalized()
	var right = up.cross(forward).normalized()
	var corrected_forward = right.cross(up).normalized()
	
	var b = Basis()
	b.x = right
	b.y = up
	b.z = corrected_forward
	
	global_transform.basis = b


func _unit_path_new(wanted_goal: Vector3) -> void:
	var safe_goal: Vector3 = NavigationServer3D.map_get_closest_point(map_RID, wanted_goal)
	path_points_packed = NavigationServer3D.map_get_path(map_RID, global_position, safe_goal, true)
	pathing = true
	pathing_point = 0


func _y_correction() -> void:
	global_position = NavigationServer3D.map_get_closest_point(map_RID, global_position)
	mesh.position.y = NavigationServer3D.map_get_cell_height(map_RID)


func _random_position_offset(target_direction: Vector3) -> Vector3:
	var randon_factor: float = 4.0
	var offset = Vector3(randf_range(-randon_factor, randon_factor), 0, randf_range(-randon_factor, randon_factor))
	return target_direction + offset
