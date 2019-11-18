extends KinematicBody

var vel = Vector3()
var force = 1*10
var pos = Vector3(0,-1,0)
var move = false

func _on_Player_b1():
		move = true
		
func _physics_process(delta):
	if (move == true):
		vel.y = force* delta
		move_and_slide(vel, pos)
		print(self.transform.translated(Vector3()))

func _on_Platform_stopP():
	move = false