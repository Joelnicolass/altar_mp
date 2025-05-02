class_name Unit extends StaticBody3D

# --- COMMON PROPERTIES --- #
var initial_transform: Transform3D
var peer: int

func _enter_tree() -> void:
	set_multiplayer_authority(peer)
	print("Unit " + str(name) + "peer:" + str(peer) + " has authority: " + str(is_multiplayer_authority()))


@export var movement_speed: float = 4.0
@onready var selected = $Selected
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var map_RID: RID = get_world_3d().get_navigation_map()

var is_selected = false
var pathing: bool = false
var pathing_point: int = 0
var path_points_packed: PackedVector3Array


func unit_path_new(wanted_goal: Vector3) -> void:
	var safe_goal: Vector3 = NavigationServer3D.map_get_closest_point(map_RID, wanted_goal)
	path_points_packed = NavigationServer3D.map_get_path(map_RID, global_position, safe_goal, true)
	pathing = true
	pathing_point = 0


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	if pathing:
		var path_next_point: Vector3 = path_points_packed[pathing_point] - global_position
		if path_next_point.length_squared() > 1.0:
			var velocity: Vector3 = (path_next_point.normalized() * delta) * movement_speed
			unit_rotate_to_direction(velocity)
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

	unit_path_new(movement_target)
	

func _ready() -> void:
	if not is_multiplayer_authority(): return

	global_transform = initial_transform
	
	await (get_tree().process_frame)
	global_position = NavigationServer3D.map_get_closest_point(map_RID, global_position)
	mesh.position.y = NavigationServer3D.map_get_cell_height(map_RID)


func unit_rotate_to_direction(direction: Vector3) -> void:
	rotation.y = atan2(-direction.x, -direction.z)
