extends RigidBody

signal moveP
signal moveB
signal notmoveB
#var bridge = load("res://Bridge.tscn") 
#var node = bridge.instance()
#var CollS

func _ready():
	connect("body_entered", self, "enter")
	connect("body_exited", self, "exit")
#	add_child(node)
#	CollS = node.get_node("CollisionBridge")
#	print("Nodo ottenuto: ", node, node.get_name())
#	print(CollS)


func enter(body):
	if body.get_name() == "Platformer":
		print("collision with ", body.get_name())
		emit_signal("moveP")
	elif body.get_name() == "Bridge":
		print("collision with a ", body.get_name())
		emit_signal("moveB")
	elif body.get_name() == "Board":
		print("enter on boards", body.get_name())
	else:
		print("Collision whith: ", body.get_name())


func exit(body):
	if body.get_name() == "Bridge":
		print("exit from bridge")
		emit_signal("notmoveB")