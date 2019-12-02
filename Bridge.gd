extends RigidBody

var r = 0
var move = false
var target
var rot
var up = Vector3(1,0,0)
onready var player = get_node("../../Player")


func on_Player_bridge():
	print("Player is on the bridge")
	move = true
	print(player.get_name())

func _on_Timer_timeout() -> void:
	apply_torque_impulse(Vector3(0.3,0,0))


#	if(move):
#		while(r < 2):
#			rotate_object_local(Vector3(1,0,0),deg2rad(0.2))
#			rotate_object_local(Vector3(1,0,0),0.05)
#			r = get_rotation_degrees().x
		#	set_global_transform(r)
	#		apply_torque_impulse(Vector3(1,0,0))
	#		target = self.global_rotate(Vector3(1,0,0),0.05)
	#		rot = player.global_rotate(Vector3(1,0,0),0.05)
#			print("rotation bridge", rotation, "  ->  ", r, "  ", self.rotation)
#		print("change")
#		while(r > -2):
		#	set_rotation_degrees(Vector3(0,0,0))
#				rotate_object_local(Vector3(-1,0,0),0.05)
#				r = get_rotation_degrees().x
#				self.rotation
	#			set_global_transform(r)
	#		apply_torque_impulse(Vector3(1,0,0))
#			target = self.global_rotate(Vector3(1,0,0),0.05)
	#		rot = player.set_rotate(Vector3(1,0,0),0.05)
#				print("rotation Bridge", rotation, "  <-  ", r, "  ", self.rotation)
	#	print("change")
	
func exit_Player_bridge():
	print("Player exit from bridge")
	move = false