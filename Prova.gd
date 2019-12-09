extends RigidBody

func _on_Timer_timeout() -> void:
	apply_torque_impulse(Vector3(0.5,0,0))