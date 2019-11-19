extends KinematicBody

signal rot
signal nrot

func _on_Player_bridge():
	print("Player is on the bridge")
	emit_signal("rot")

func _exit_Player_bridge():
	print("Player exit")
	emit_signal("nrot")