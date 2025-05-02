extends Node3D

@onready var mesh: StaticBody3D = $map/StaticBody3D

func _ready():
    if not is_multiplayer_authority(): return
    
    mesh.add_to_group("terrain")