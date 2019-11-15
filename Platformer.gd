extends KinematicBody

var vel_act = Vector3()
var force = 9.81*10 
var pos = Vector3(0,1,0)
var move = false

func _on_RigidBody_Player_moveP():
	move = true

func _physics_process(delta):
	if (move == true):
		vel_act.y = force* delta
		move_and_slide(vel_act, pos)
	#	print(self.transform.translated(Vector3()))

func _on_Platform_stopP():
	self.transform.translated(Vector3(-18.299999, 10.7, 0))
#	set_physics_process(false)