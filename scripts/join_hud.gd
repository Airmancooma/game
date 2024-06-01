extends Control

@onready var host = $CanvasLayer/host
@onready var join = $CanvasLayer/join
@onready var team_1 = $CanvasLayer/team_1
@onready var team_2 = $CanvasLayer/team_2

func _ready():
	#host.hide()
	team_1.hide()
	team_2.hide()
	
func _on_host_pressed():
	host.hide()
	join.hide()
	MultiplayerManager.host()

func _on_join_pressed():
	host.hide()
	join.hide()
	MultiplayerManager.join()

func _on_team_1_pressed():
	pass # Replace with function body.

func _on_team_2_pressed():
	pass # Replace with function body.


