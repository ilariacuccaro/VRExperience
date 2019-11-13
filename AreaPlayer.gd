extends Area

onready var animationPlatform = get_node("../../../World/Platformer/AnimationP")
onready var animationCamera = get_node("../../AnimationC")
onready var Bridge = preload("res://Bridge.tscn")
var node
var animationBridge

func _ready():
	connect("body_entered", self, "platform_enter")
	#if(node == null):
	node = Bridge.instance() #creo una nuova istanza di bridge
	add_child(node) #aggiungo il nodo attuale 
	print(node)
	animationBridge = node.get_node("AnimationB")
	print(animationBridge)
	connect("body_entered", self, "bridge_enter")
	#connect("body_exited", self, "bridge_exited")

func platform_enter(body):
	#print(body, " entered area")
	if body.get_name() == "Platformer":
		animationPlatform.play("MovingP") 
		animationCamera.play("MoveCamera")

func bridge_enter(body):
	print(body, " entered in a bridge")
	print(body.get_name())
	if body.get_name() == "Bridge":
		animationBridge.play("MovingBridge")
		
#func bridge_exited(body):
#	if  body.get_name() != "Bridge":
#		animationBridge.stop()