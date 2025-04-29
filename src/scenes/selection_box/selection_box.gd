"""
	- All units should be in the "units" group to be selected
	- The selected units will be added to the "selected_units" group
"""


extends Node2D


var camera: Camera3D # our 3D game camera
@onready var nine_patch_rect = $Panel # to visualize selection rectangle

var is_selecting = false # is currently selecting?
var selection_start = Vector2() # start of selection rectangle
var selection_rect = Rect2() # end of selection rectangle


func _ready():
	camera = get_viewport().get_camera_3d()


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Start selection
				is_selecting = true
				selection_start = get_global_mouse_position()
				nine_patch_rect.position = selection_start
				nine_patch_rect.size = Vector2()
			else:
				# End selection
				if is_selecting:
					is_selecting = false
					nine_patch_rect.visible = false
					_select_units()
		# De-select all units if RMB is pressed
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_clear_previous_selection()

	elif event is InputEventMouseMotion:
		if is_selecting:
			# Show selection box only when mouse is dragged and rect is larger than (32,32)
			if selection_rect.size.length() > 32:
				nine_patch_rect.visible = true
			else:
				nine_patch_rect.visible = false


func _process(_delta):
	if is_selecting:
		# Continuously update the selection rectangle to match the mouse position
		var current_mouse_position = get_global_mouse_position()
		selection_rect = Rect2(selection_start, current_mouse_position - selection_start).abs()
		nine_patch_rect.position = selection_rect.position
		nine_patch_rect.size = selection_rect.size

func _select_units():
	# if selected items are already there, do nothing
	# Let the user de-select the units by pressing RMB
	if get_tree().get_nodes_in_group("selected_units").size() > 0:
		print("Already selected units, de-select them first")
		return
	
	# Also select unit if they are just clicked, not in selection box
	# passing collision_mask of Units to check for only units (and not return terrain, etc)
	var clicked_object = RaycastSystem.get_raycast_hit_object(1)
	if clicked_object and clicked_object in get_tree().get_nodes_in_group("units"):
		clicked_object.add_to_group("selected_units")
		print("Clicked object:", clicked_object.name)
	
	# select all the units within the selection rectangle, by using unproject_position
	for unit in get_tree().get_nodes_in_group("units"):
		var unit_screen_position = camera.unproject_position(unit.global_transform.origin)
		if selection_rect.has_point(unit_screen_position):
			unit.add_to_group("selected_units") # Add to seloected units group
			print("Selected unit:", unit.name)


# Clear the previous selection
func _clear_previous_selection():
	for selected_unit in get_tree().get_nodes_in_group("selected_units"):
		selected_unit.remove_from_group("selected_units")
		print("De-selected unit:", selected_unit.name)
