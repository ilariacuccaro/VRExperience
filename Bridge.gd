extends KinematicBody

var move = false
var dir = 0

func _on_Player_bridge():
	print("Player is on the bridge")
	move = true

func _physics_process(delta):
	if(move == true):
		$Spatial/AnimationB.play("MovingBridge")
#	if (move == true):
#		$Spatial/Cubes.rotation_degrees(Vector3(5,0,0))
#		$Spatial/Cubes.rotation_degrees(Vector3(0,0,0))
#		$Spatial/Cubes.rotation_degrees(Vector3(-5,0,0))
#		$Spatial/Cubes.rotation_degrees(Vector3(0,0,0))
		

func _exit_Player_bridge():
	move = false