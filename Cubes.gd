extends KinematicBody

var move = false
var r = 0

func _on_Bridge():
	move = true


func _physics_process(delta):
	if(move == true):
		move()


func move():
	while(r < 1.2):
		rotate_object_local(Vector3(1,0,0),deg2rad(0.3))
		r = get_rotation_degrees().x
		print(rotation, "  ->  ", r)
	print ("stop rotation")
	while(r > -1.2):
		rotate_object_local(Vector3(-1,0,0),deg2rad(0.3))
		r = get_rotation_degrees().x
		print(rotation, "  <-  ", r)


func _exit_Bridge():
	move = false