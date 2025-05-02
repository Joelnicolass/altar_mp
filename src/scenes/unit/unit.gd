class_name Unit extends RigidBody3D

# --- COMMON PROPERTIES --- #
var initial_transform: Transform3D
var peer: int

func _enter_tree() -> void:
	set_multiplayer_authority(peer)
	print("Unit " + str(name) + "peer:" + str(peer) + " has authority: " + str(is_multiplayer_authority()))


@onready var selected = $Selected
@onready var navigation_agent = $NavigationAgent3D
@export var movement_speed: float = 4.0

var is_selected = false

func set_is_selected(value: bool) -> void:
	is_selected = value
	selected.visible = value


func move_to(movement_target: Vector3) -> void:
	navigation_agent.set_target_position(movement_target)


func _ready() -> void:
	if not is_multiplayer_authority(): return

	global_transform = initial_transform
	navigation_agent.velocity_computed.connect(Callable(_on_velocity_computed))

	
func _physics_process(delta):
	if not is_multiplayer_authority(): return

	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0: return
	if navigation_agent.is_navigation_finished(): return

	var next_path_position: Vector3 = navigation_agent.get_next_path_position()
	var new_velocity: Vector3 = global_position.direction_to(next_path_position) * movement_speed
	if navigation_agent.avoidance_enabled:
		navigation_agent.set_velocity(new_velocity)
	else:
		_on_velocity_computed(new_velocity)


func _on_velocity_computed(safe_velocity: Vector3):
	linear_velocity = safe_velocity
