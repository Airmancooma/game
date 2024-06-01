extends MultiplayerSynchronizer

@onready var player = $".."

var input_direction

func _ready():
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		set_process(false)
		set_physics_process(false)
	
	input_direction = Input.get_axis("move_left", "move_right")

func _physics_process(delta):
	if player.set_username:
		if player.is_hit != true:
			input_direction = Input.get_axis("move_left", "move_right")

func _process(delta):
	if player.is_hit != true:
		if Input.is_action_just_pressed("jump") and not player.is_gugol and player.set_username:
			jump.rpc()
		
		if Input.is_action_just_pressed("gugol"):
			gugol.rpc()
		
		if Input.is_action_just_pressed("shoot") and player.set_username:
			shoot.rpc()

func _on_username_line_text_submitted(text):
	username.rpc(str(text))

@rpc("authority", "call_remote")
func username(set_name):
	if multiplayer.is_server():
		var player_id = get_multiplayer_authority()
		var success = MultiplayerManager.update_player_username(player_id, set_name)
		if success:
			player.set_username = true
			player.if_username.rpc_id(player_id)
			player.set_username_label(set_name)
		else:
			player.username_error.rpc_id(player_id,"This username already exists")

@rpc("call_local")
func jump():
	if multiplayer.is_server():
		player.do_jump = true

@rpc("call_local")
func gugol():
	if multiplayer.is_server():
		player.gugol_count += 1
		if player.gugol_count == 1:
			player.is_gugol = true
			player.gugol_down_anim = false

@rpc("call_local")
func shoot():
	if multiplayer.is_server():
		player.is_shoot = true
