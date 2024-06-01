extends Control

@export var hud_id := 1:
	set(id):
		hud_id = id
		$HUDSynchronizer.set_multiplayer_authority(id)
		$CanvasLayer/Player_id_test.text = str(id)
