extends Area2D

@export var speed = 400
var direction = Vector2.RIGHT

func _ready():
	if direction == Vector2.LEFT:
		$Sprite2D.flip_h = true
	else:
		$Sprite2D.flip_h = false

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body is CharacterBody2D and body.name != str(multiplayer.get_unique_id()):
		body.remote_hit()
	queue_free()
