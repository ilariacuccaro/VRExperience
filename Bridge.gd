extends RigidBody

var move = false
onready var timer = get_node("../../Timer")


func on_Player_bridge():
	print("Player is on the bridge")
	timer.start()

func _on_Timer_timeout() -> void:
	apply_torque_impulse(Vector3(0.1,0,0))

func exit_Player_bridge():
	print("Player exit from bridge")
	timer.stop()