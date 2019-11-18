extends RigidBody

signal moveP
signal moveB
signal b1

func _ready():
	connect("body_entered", self, "platform_enter")
	connect("body_entered", self, "bridge_enter")
	connect("body_exited", self, "bridge_exit")
#	connect("body_entered", self, "b1_enter")
#	connect("body_exited", self, "b1_exit")


func platform_enter(body):
	if body.get_name() == "Platformer":
		print("collision with platform", body.get_name())
		emit_signal("moveP")

func bridge_enter(body):
	if body.get_name() == "Bridge":
		print("collision with a bridge", body.get_name())
		emit_signal("moveB")
	#	connect("moveB", self, "_on_Player_bridge")
		
func bridge_exit(body):
		emit_signal("moveB")
	
#func b1_enter(body):
#	if body.get_name() == "Board1":
#		connect("b1", self, "_on_Player_b1")
		
#func b1_exit(body):
#	connect("b1", self, "_exit_Player_b1")