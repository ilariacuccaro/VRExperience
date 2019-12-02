extends RigidBody

signal moveP
signal moveB
signal notmoveB
var r = 0
var state
var current_transform
var target_position
#var bridge = load("res://Bridge4.tscn") 
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
		print("collision with platform", body.get_name())
		emit_signal("moveP")
	elif body.get_name() == "Bridge":
		print("collision with a bridge / ", body.get_name())
		emit_signal("moveB")
	elif body.get_name() == "Board":
		print("enter on boards", body.get_name())
	else:
		print("Collision whith: ", body.get_name())


func _integrate_forces(state):
	pass

func exit(body):
	if body.get_name() == "Bridge":
		print("exit from bridge")
		emit_signal("notmoveB")
		