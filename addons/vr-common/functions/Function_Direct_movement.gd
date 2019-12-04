extends Spatial

export (NodePath) var origin = null
export (NodePath) var camera = null

# dimensione del nostro giocatore
export var player_height = 1.8 setget set_player_height, get_player_height
export var player_radius = 0.4 setget set_player_radius, get_player_radius

# per combattere la cinetosi faremo un passo avanti nella rotazione a sinistra/a destra
export var turn_delay = 0.2
export var turn_angle = 20.0
export var max_speed = 5.0
export var drag_factor = 0.1

var turn_step = 0.0
var velocity = Vector3(0.0, 0.0, 0.0)
var gravity = -30.0
onready var collision_shape = get_node("KinematicBody/CollisionShape")
onready var tail = get_node("KinematicBody/Tail")

func get_player_height():
	return player_height

func set_player_height(p_height):
	player_height = p_height
	
	if collision_shape:
		# la misurazione dell'altezza della collision_shape è metà in alto, metà in basso dal centro
		collision_shape.shape.height = (player_height / 2.0)
		collision_shape.translation = Vector3(0.0, player_height / 2.0, 0.0)

func get_player_radius():
	return player_radius

func set_player_radius(p_radius):
	player_radius = p_radius
	
	if collision_shape:
		collision_shape.shape.height = (player_height / 2.0)
		collision_shape.shape.radius = player_radius

func _ready():
	set_player_height(player_height)
	set_player_radius(player_radius)

func _physics_process(delta):
	if !origin:
		return
	
	var arvr_camera = null
	if camera:
		arvr_camera = get_node(camera)
	else:
		arvr_camera = 	get_viewport().get_camera()
	
	if !arvr_camera:
		return;
	
	var controller = get_parent()
	if controller.get_is_active():
		var left_right = controller.get_joystick_axis(0)
		var forwards_backwards = controller.get_joystick_axis(1)
		
		################################################################
		#al primo controllo non dovremmo aver problemi
		if (abs(left_right) > 0.1):
			if left_right > 0.0:
				if turn_step < 0.0:
					turn_step = 0
			
				turn_step += left_right * delta
			else:
				if turn_step > 0.0:
					turn_step = 0
			
				turn_step += left_right * delta
		
			if abs(turn_step) > turn_delay:
				#ruotiamo attorno la nostra telecamera, regoliamo la nostra origine
				var t1 = Transform()
				var t2 = Transform()
				var rot = Transform()
			
				t1.origin = -arvr_camera.transform.origin
				t2.origin = arvr_camera.transform.origin
			
				# rotazione
				while abs(turn_step) > turn_delay:
					if (turn_step > 0.0):
						rot = rot.rotated(Vector3(0.0,-1.0,0.0),turn_angle * PI / 180.0)
						turn_step -= turn_delay
					else:
						rot = rot.rotated(Vector3(0.0,1.0,0.0),turn_angle * PI / 180.0)
						turn_step += turn_delay
				
				get_node(origin).transform *= t2 * rot * t1
		else:
			turn_step = 0.0
		
		################################################################
		# iniziamo il nostro movimento
		# posizioniamo il nostro KinematicBody nel posto giusto centrandolo sulla telecamera ma posizionandolo a terra 
		var new_transform = $KinematicBody.global_transform
		var camera_transform = arvr_camera.global_transform
		new_transform.origin = camera_transform.origin
		new_transform.origin.y = get_node(origin).global_transform.origin.y
		$KinematicBody.global_transform = new_transform
		
		# gestiamo la gravità separatamente
		var gravity_velocity = Vector3(0.0, velocity.y, 0.0)
		velocity.y = 0.0
		
		# applichiamo la resistenza
		velocity *= (1.0 - drag_factor)
		
		if (abs(forwards_backwards) > 0.1 and tail.is_colliding()):
			var dir = camera_transform.basis.z
			dir.y = 0.0
			
			velocity = dir.normalized() * -forwards_backwards * delta * max_speed * ARVRServer.world_scale
#			velocity = velocity.linear_interpolate(dir, delta * 100.0)
		
		velocity = $KinematicBody.move_and_slide(velocity, Vector3(0.0, 1.0, 0.0))
		
		gravity_velocity.y += gravity * delta
		gravity_velocity = $KinematicBody.move_and_slide(gravity_velocity, Vector3(0.0, 1.0, 0.0))
		velocity.y = gravity_velocity.y
		
		# usiamo la nostra nuova posizione per spostare il nostro punto di origine
		var movement = ($KinematicBody.global_transform.origin - new_transform.origin)
		get_node(origin).global_transform.origin += movement
		
		$KinematicBody.global_transform.origin = new_transform.origin
		
		# get_node(origin).translation -= dir.normalized() * delta * forwards_backwards * max_speed * ARVRServer.world_scale;