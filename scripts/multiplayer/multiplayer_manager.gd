extends Node

const SERVER_PORT = 9090
const SERVER_IP = "localhost" #138.2.183.51

var multiplayer_scene = preload("res://scenes/multiplayer_player.tscn")

var _players_spawn_node
var host_mode_enabled = false
var multiplayer_mode_enabled = false
var respawn_point = Vector2(30, 0)
var db

func _ready():
	if OS.has_feature("dedicated_server"):
		db = SQLite.new()
		db.path = "user://user_data.db"
		db.open_db()
		create_user_table()

func create_user_table():
	if not OS.has_feature("dedicated_server"):
		return
	var create_table_query = """
	CREATE TABLE IF NOT EXISTS users (
		id INTEGER PRIMARY KEY,
		username TEXT NOT NULL UNIQUE
	);
	"""
	db.query(create_table_query)

func host():
	print("Starting host!")
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	multiplayer_mode_enabled = true
	host_mode_enabled = true

	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = server_peer

	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	
	if not OS.has_feature("dedicated_server"):
		_add_player_to_game(1)

func join():
	print("Player joining")
	multiplayer_mode_enabled = true
		  
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = client_peer

func _add_player_to_game(id: int):
	print("Player %s joined the game!" % id)

	var player_to_add = multiplayer_scene.instantiate()
	player_to_add.player_id = id
	player_to_add.name = str(id)
	
	_players_spawn_node.add_child(player_to_add, true)
	# Add player to database
	save_player_to_db(id, "")

func _del_player(id: int):
	print("Player %s left the game!" % id)
	if not _players_spawn_node.has_node(str(id)):
		return
	_players_spawn_node.get_node(str(id)).queue_free()
	# Remove player from database
	delete_player_from_db(id)

func save_player_to_db(id: int, username: String):
	if not OS.has_feature("dedicated_server"):
		return
	var query = "INSERT OR REPLACE INTO users (id, username) VALUES (?, ?);"
	var params = [id, username]
	db.query_with_bindings(query, params)

func delete_player_from_db(id: int):
	if not OS.has_feature("dedicated_server"):
		return
	var query = "DELETE FROM users WHERE id = ?;"
	var params = [id]
	db.query_with_bindings(query, params)

func update_player_username(id: int, username: String):
	if not OS.has_feature("dedicated_server"):
		return
	
	# Check if the username already exists
	var check_query = "SELECT COUNT(*) AS count FROM users WHERE username = ?;"
	var success = db.query_with_bindings(check_query, [username])
	
	if success and db.query_result.size() > 0:
		var count = db.query_result[0]['count']
		if count > 0:
			print("Error: Username already exists")
			return false
	
	var query = "UPDATE users SET username = ? WHERE id = ?;"
	var params = [username, id]
	db.query_with_bindings(query, params)
	return true

