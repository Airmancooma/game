extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -350.0

@onready var animated_sprite = $AnimatedSprite2D
@onready var text_visibiliti = $text_visibiliti

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var direction = 1
var do_jump = false
var _is_on_floor = true
var alive = true
var gugol_count = 0
var is_gugol = false
var gugol_down_anim = false
var gugol_up_anim = true
var set_username = false
var is_shoot = false
var shoot_direction = false
var is_hit = false

@export var player_id := 1:
	set(id):
		player_id = id
		%InputSynchronizer.set_multiplayer_authority(id)

@export var bullet_scene: PackedScene

func _ready():
	if multiplayer.get_unique_id() == player_id:
		$Camera2D.make_current()
		$HUD/CanvasLayer/Username_line.visible = true
	else:
		$Camera2D.enabled = false
		$HUD/CanvasLayer/Username_line.visible = false

@rpc("call_local")
func if_username():
	$HUD/CanvasLayer/Username_line.visible = false

func set_username_label(username):
	$HUD/CanvasLayer/Username_line.visible = false
	$Username.text = str(username,"\n",player_id)

@rpc("call_local")
func username_error(error):
	$Error.text = error
	text_visibiliti.start()

func _apply_animations(delta):
	if direction > 0:
		shoot_direction = false
		animated_sprite.flip_h = false
	elif direction < 0:
		shoot_direction = true
		animated_sprite.flip_h = true
	if is_hit != true:
		if _is_on_floor:
			if gugol_count == 1 and gugol_down_anim:
				animated_sprite.play("gugol_down")
				gugol_down_anim = false
			elif gugol_count == 2 and gugol_up_anim:
				animated_sprite.play("gugol_up")
				gugol_count = 0
				is_gugol = false
				gugol_down_anim = true 
				gugol_up_anim = false
			elif not gugol_down_anim:
				if animated_sprite.animation != "gugol_down":
					gugol_down_anim = true
			elif not gugol_up_anim:
				if animated_sprite.animation != "gugol_up":
					gugol_up_anim = true
			else:
				if direction == 0 and not is_gugol:
					animated_sprite.play("idle")
				else:
					animated_sprite.play("run")
		else:
			animated_sprite.play("jump")

func _apply_movement_from_input(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	if do_jump and is_on_floor():
		velocity.y = JUMP_VELOCITY
		do_jump = false

	if is_gugol:
		velocity.x = 0
		direction = %InputSynchronizer.input_direction
		if direction > 0:
			animated_sprite.flip_h = false
		elif direction < 0:
			animated_sprite.flip_h = true
	else:
		direction = %InputSynchronizer.input_direction
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func _physics_process(delta):
	if multiplayer.is_server():
		if not alive and is_on_floor():
			_set_alive()
		
		_is_on_floor = is_on_floor()
		_apply_movement_from_input(delta)
		
		if is_shoot:
			shoot.rpc()
			is_shoot = false

	if not multiplayer.is_server() || MultiplayerManager.host_mode_enabled:
		_apply_animations(delta)

@rpc("call_remote")
func shoot():
	var bullet = bullet_scene.instantiate()
	if shoot_direction:
		bullet.position = position + Vector2(-12, -14)
		bullet.direction = Vector2.LEFT  # Balra lövés
	else:
		bullet.position = position + Vector2(12, -14)
		bullet.direction = Vector2.RIGHT  # Jobbra lövés
	get_parent().add_child(bullet)

func remote_hit():
	rpc_id(1, "report_hit")

@rpc("any_peer","call_remote")
func report_hit():
	if multiplayer.is_server() && is_hit == false:
		hit.rpc()
		mark_dead()

@rpc("call_remote")
func hit():
	is_hit = true
	if is_hit:
		animated_sprite.play("die")

func mark_dead():
	print("Mark player dead!")
	alive = false
	is_hit = true
	$CollisionShape2D.set_deferred("disabled", true)
	$RespawnTimer.start()

func _respawn():
	print("Respawned!")
	position = MultiplayerManager.respawn_point
	$CollisionShape2D.set_deferred("disabled", false)

func _set_alive():
	print("alive again!")
	alive = true
	is_hit = false
	#Engine.time_scale = 1.0

func _on_animated_sprite_2d_animation_finished():
	if animated_sprite.animation == "gugol_up":
		gugol_up_anim = true

func _on_text_visibiliti_timeout():
	$Error.text = ""
	text_visibiliti.stop()
