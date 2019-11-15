extends RigidBody

signal moveP

func _ready():
	connect("body_entered", self, "platform_enter")


func platform_enter(body):
	if body.get_name() == "Platformer":
		print("collision with platform", body.get_name())
		emit_signal("moveP")
