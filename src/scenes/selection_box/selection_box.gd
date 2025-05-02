extends Node2D

var camera: Camera3D
@onready var nine_patch_rect = $Panel
@onready var player: CharacterBody3D = get_owner()

var is_selecting = false
var selection_start = Vector2()
var selection_rect = Rect2()
var is_adding_unit = false

const MIN_VALID_DRAG = 32
const GROUP_SELECTED_UNITS = "selected_units"
const GROUP_UNITS = "units"
const GROUP_PLAYER = "player"
const GROUP_TERRAIN = "terrain"
const GROUP_BUILDINGS = "buildings"

var is_authority = false


func _ready():
	if not is_authority: return
	

func _input(event):
	if not is_authority: return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				_handle_left_click(event)
			MOUSE_BUTTON_RIGHT:
				_handle_right_click(event)
	
	if event is InputEventMouseMotion:
		_handle_mouse_motion()


func _process(_delta):
	if not is_authority: return

	if is_selecting:
		var current_mouse_position = get_global_mouse_position()
		selection_rect = Rect2(selection_start, current_mouse_position - selection_start).abs()
		nine_patch_rect.position = selection_rect.position
		nine_patch_rect.size = selection_rect.size


# --- SELECTION FUNCTIONS --- #

func _select_units():
	var clicked_object = RaycastSystem.get_raycast_hit_object(1)

	# SI ES UNA UNIDAD
	if clicked_object and clicked_object in get_tree().get_nodes_in_group(GROUP_UNITS):
		# SI YA ESTABA SELECCIONADA, LA DESELECCIONA
		if clicked_object.is_in_group(GROUP_SELECTED_UNITS):
			clicked_object.remove_from_group(GROUP_SELECTED_UNITS)
			if clicked_object is Unit:
				clicked_object.set_is_selected(false)
			print("De-selected unit:", clicked_object.name)
		# SI NO ESTABA SELECCIONADA, LA SELECCIONA
		else:
			clicked_object.add_to_group(GROUP_SELECTED_UNITS)
			if clicked_object is Unit:
				clicked_object.set_is_selected(true)
			print("Clicked object:", clicked_object.name)

	# SI NO HAY NINGUN CLICKED OBJECT, SELECCIONA UNIDADES EN EL RECTANGULO
	for unit in get_tree().get_nodes_in_group(GROUP_UNITS):
		var unit_screen_position = camera.unproject_position(unit.global_transform.origin)
		if selection_rect.has_point(unit_screen_position):
			unit.add_to_group(GROUP_SELECTED_UNITS)
			if unit is Unit:
				if not unit.is_selected:
					unit.set_is_selected(true)
			print("Selected unit:", unit.name)


func _clear_previous_selection():
	for selected_unit in get_tree().get_nodes_in_group(GROUP_SELECTED_UNITS):
		selected_unit.remove_from_group(GROUP_SELECTED_UNITS)

		if selected_unit is Unit:
			selected_unit.set_is_selected(false)

		print("De-selected unit:", selected_unit.name)


func _handle_start_selection():
	if Input.is_action_pressed("command"):
		is_adding_unit = true
	else:
		is_adding_unit = false

	if not is_adding_unit: _clear_previous_selection()
	is_selecting = true
	selection_start = get_global_mouse_position()
	nine_patch_rect.position = selection_start
	nine_patch_rect.size = Vector2()


func _handle_end_selection():
	if is_selecting:
		is_selecting = false
		nine_patch_rect.visible = false
		_select_units()


# --- MOUSE HANDLERS --- #

func _handle_mouse_motion():
	if is_selecting:
		if selection_rect.size.length() > MIN_VALID_DRAG:
			nine_patch_rect.visible = true
		else:
			nine_patch_rect.visible = false


func _handle_left_click(event: InputEventMouseButton):
	if event.is_pressed():
		_handle_start_selection()
	else:
		_handle_end_selection()


func _handle_right_click(event: InputEventMouseButton):
	if event.is_released():
		var _selected_units = get_tree().get_nodes_in_group(GROUP_SELECTED_UNITS)
		var has_selected_units = _selected_units.size() > 0

		var clicked_object = RaycastSystem.get_raycast_hit_object(1)
		var coordinates = RaycastSystem.get_mouse_world_position(1)
		var _groups = clicked_object.get_groups()
		
		var is_player = _groups.has(GROUP_PLAYER)
		var is_terrain = _groups.has(GROUP_TERRAIN)
		var is_unit = _groups.has(GROUP_UNITS)

		if is_unit:
			print("Clicked unit:", clicked_object.name)
		
		if is_player:
			print("Clicked player:", clicked_object.name)
		
		if is_terrain:
			# mover unidades
			if has_selected_units:
				for unit in _selected_units:
					if unit is Unit:
						unit.move_to(coordinates)
