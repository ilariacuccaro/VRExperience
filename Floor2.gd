extends RigidBody

signal stopP

func _ready():
	connect("body_entered", self, "platform_stop")

func platform_stop(body):
	if body.get_name() == "Platformer":
		print("collision with platform", body.get_name())
		emit_signal("stopP")