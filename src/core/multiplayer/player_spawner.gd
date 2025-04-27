extends MultiplayerSpawner

@export var player: PackedScene

func _init() -> void:
  spawn_function = _spawn_custom

func _spawn_custom(data: Variant) -> Node:
  var scene = player.instantiate()
  scene.name = str(data.peer_id)
  scene.initial_transform = data.initial_transform
  scene.get_node('MultiplayerSynchronizer').set_multiplayer_authority(data.peer_id)

  return scene
