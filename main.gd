extends Node

const FLAG_HEADLESS: String = "headless"
const FLAG_DEDICATED_SERVER: String = "dedicated_server"
const PORT: int = 7777
const MAX_CLIENTS: int = 16
const IP_SERVER: String = "localhost"

@onready var menu_hud: CanvasLayer = $Menu
#@onready var player_spawner: MultiplayerSpawner = $PlayerSpawner
#@onready var world: Node3D = $World

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()


func _ready() -> void:
	_initialize_events()

	if OS.has_feature(FLAG_DEDICATED_SERVER):
		_create_server()
	elif DisplayServer.get_name() == FLAG_HEADLESS:
		_create_server()


func _create_server():
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error: return error

	multiplayer.multiplayer_peer = peer
	menu_hud.hide()
	print("Server created on port: " + str(PORT))


func _create_client():
	var error = peer.create_client(IP_SERVER, PORT)
	if error: return error

	multiplayer.multiplayer_peer = peer
	menu_hud.hide()
	print("Client connected with ID: " + str(peer.get_unique_id()))


func _add_player(id: int) -> void:
	#player_spawner.spawn({
	#	'peer_id': id,
	#	'initial_transform': Transform3D(Basis(), Vector3(randf_range(-2, 2), 0, 0))
	#})
	print("Player added: ", id)


func _remove_player(id: int) -> void:
	#var player = world.get_node(str(id))
	#if player:
	#	player.queue_free()
		print("Player removed: ", id)


# UI controllers

func _on_host_pressed() -> void:
	_create_server()


func _on_join_pressed() -> void:
	_create_client()


# Events

func _initialize_events() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_peer_connected(id: int = 1) -> void:
	if not multiplayer.is_server(): return
	_add_player(id)

	
func _on_connected_to_server():
	if not multiplayer.is_server(): return
	print("Connected to server")


func _on_connection_failed():
	if not multiplayer.is_server(): return
	print("Connection failed")


func _on_peer_disconnected(id):
	if not multiplayer.is_server(): return
	_remove_player(id)
