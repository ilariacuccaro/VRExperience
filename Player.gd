extends RigidBody

#var gravity = 9.8
#var pos = Vector3(0,1,0)
#var vel = Vector3()
signal moveP
signal moveB
signal notmoveB

func _ready():
	connect("body_entered", self, "enter")
	connect("body_exited", self, "exit")

func _physics_process(delta):
	get_gravity_scale()
#		vel.y = gravity*delta
#		move_and_slide(vel, pos)

func enter(body):
	if body.get_name() == "Platformer":
		print("collision with platform", body.get_name())
		emit_signal("moveP")
	if body.get_name() == "Bridge":
		print("collision with a bridge", body.get_name())
		emit_signal("moveB")

func exit(body):
	if body.get_name() == "Bridge":
		emit_signal("notmoveB")