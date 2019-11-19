extends RigidBody

signal moveP
signal moveB
signal notmoveB

func _ready():
	connect("body_entered", self, "platform_enter")
	connect("body_entered", self, "bridge_enter")
	connect("body_exited", self, "bridge_exit")


func platform_enter(body):
	if body.get_name() == "Platformer":
		print("collision with platform", body.get_name())
		emit_signal("moveP")

func bridge_enter(body):
	if body.get_name() == "Bridge":
		print("collision with a bridge", body.get_name())
		emit_signal("moveB")

func bridge_exit(body):
		emit_signal("notmoveB")