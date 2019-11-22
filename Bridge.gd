extends KinematicBody

var r = 0
var move = false

func on_Player_bridge():
	print("Player is on the bridge")
	move = true


func _physics_process(delta):
	if(move):
		while(r < 2.2):
#			rotate_object_local(Vector3(1,0,0),deg2rad(0.2))
			rotate_object_local(Vector3(1,0,0),0.05)
			r = get_rotation_degrees().x
			print("rotation bridge", rotation, "  ->  ", r)
	#	print("change")
		while(r > -2.2):
		#	set_rotation_degrees(Vector3(0,0,0))
			rotate_object_local(Vector3(-1,0,0),0.05)
			r = get_rotation_degrees().x
			print("rotation Bridge", rotation, "  <-  ", r)
	#	print("change")
	
func exit_Player_bridge():
	print("Player exit from bridge")
	move = false