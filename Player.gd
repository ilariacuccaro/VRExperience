extends RigidBody

#var gravity = 9.8
#var pos = Vector3(0,1,0)
#var vel = Vector3()
signal moveP
signal moveB
signal notmoveB
var r = 0
var move = false
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
	if body.get_name() == "Bridge":
		print("collision with a bridge / ", body.get_name())
		move = true
		emit_signal("moveB")
	if body.get_name() == "Board":
		print("enter on boards", body.get_name())
	print("Collision whith: ", body.name)

#func _physics_process(delta):
#	if(move):
#		while(r < 2.2):
#				rotate_object_local(Vector3(1,0,0),0.05499499)
#				r = get_rotation_degrees().x
#				print("rotation Player", rotation, "  ->  ", r)
		#	print("change")
#		while(r > -2.2):
			#	set_rotation_degrees(Vector3(0,0,0))
#				rotate_object_local(Vector3(-1,0,0),0.05499499)
#				r = get_rotation_degrees().x
#				print("rotation Player", rotation, "  <-  ", r)

func exit(body):
	if body.get_name() == "Bridge":
		print("exit from bridge")
		move = false
		emit_signal("notmoveB")