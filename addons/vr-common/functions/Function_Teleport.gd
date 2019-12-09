extends KinematicBody

export var teleport_button = 15
export (Color) var can_teleport_color = Color(0.0, 1.0, 0.0, 1.0)
export (Color) var cant_teleport_color = Color(1.0, 0.0, 0.0, 1.0)
export (Color) var no_collision_color = Color(45.0 / 255.0, 80.0 / 255.0, 220.0 / 255.0, 1.0)
export var player_height = 1.8 setget set_player_height, get_player_height
export var player_radius = 0.4 setget set_player_radius, get_player_radius
export var strength = 5.0
# export var collision_mask = 1

onready var ws = ARVRServer.world_scale
var origin_node = null
var player = null
var is_on_floor = true
var is_teleporting = false
var can_teleport = true
var teleport_rotation = 0.0;
var floor_normal = Vector3(0.0, 1.0, 0.0)
var last_target_transform = Transform()
var collision_shape = null
var step_size = 0.5

# Di default mostriamo una capsula per indicare dove il giocatore atterra
onready var capsule = get_node("Target/Player_figure/Capsule")

func get_player_height():
	return player_height

func set_player_height(p_height):
	player_height = p_height
	
	if collision_shape:
		
		collision_shape.height = (player_height / 2.0) + 0.1
		
		if capsule:
			capsule.mesh.mid_height = player_height - (2.0 * player_radius)
			capsule.translation = Vector3(0.0, player_height/2.0, 0.0)

func get_player_radius():
	return player_radius

func set_player_radius(p_radius):
	player_radius = p_radius
	
	if collision_shape:
		collision_shape.radius = player_radius

		if capsule:
			capsule.mesh.mid_height = player_height - (2.0 * player_radius)
			capsule.mesh.radius = player_radius

func _ready():
	origin_node = get_node("../..")
	player = get_node("../../..")

	$Teleport.visible = false
	$Target.visible = false
	
	$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
	$Target.mesh.size = Vector2(ws, ws)
	$Target/Player_figure.scale = Vector3(ws, ws, ws)
	
	collision_shape = CapsuleShape.new()
	
	set_player_height(player_height)
	set_player_radius(player_radius)

func _physics_process(delta):
	var controller = get_parent()
	
	var new_ws = ARVRServer.world_scale
	if ws != new_ws:
		ws = new_ws
		$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
		$Target.mesh.size = Vector2(ws, ws)
		$Target/Player_figure.scale = Vector3(ws, ws, ws)
	
	if controller and controller.get_is_active() and controller.is_button_pressed(teleport_button):
		if !is_teleporting:
			is_teleporting = true
			$Teleport.visible = true
			$Target.visible = true
			teleport_rotation = 0.0
		
		var space = PhysicsServer.body_get_space(self.get_rid())
		var state = PhysicsServer.space_get_direct_state(space)
		var query = PhysicsShapeQueryParameters.new()
		
		query.collision_mask = collision_mask
		query.margin = get_safe_margin()
		query.shape_rid = collision_shape.get_rid()
		
		var shape_transform = Transform(Basis(Vector3(1.0, 0.0, 0.0), deg2rad(90.0)), Vector3(0.0, player_height / 2.0, 0.0))
		
		var teleport_global_transform = $Teleport.global_transform
		var target_global_origin = teleport_global_transform.origin
		var down = Vector3(0.0, -1.0 / ws, 0.0)
		
		############################################################

		var cast_length = 0.0
		var fine_tune = 1.0
		var hit_something = false
		for i in range(1,26):
			var new_cast_length = cast_length + (step_size / fine_tune)
			var global_target = Vector3(0.0, 0.0, -new_cast_length)
			
			var t = global_target.z / strength
			var t2 = t * t
			
			global_target = teleport_global_transform.xform(global_target)
			
			# sistemiamo la gravità
			global_target += down * t2
			
			# testiamo se la nostra nuova posizione è in collisione
			query.transform = Transform(Basis(), global_target) * shape_transform
			var cast_result = state.collide_shape(query, 10)
			if cast_result.empty():
				# non siamo entrati in collisione, controlliamo la prossima sezione
				cast_length = new_cast_length
				target_global_origin = global_target
			elif (fine_tune <= 16.0):
				# proviamo di nuovo con un piccolo passo
				fine_tune *= 2.0
			else:
				var collided_at = target_global_origin
				if global_target.y > target_global_origin.y:
					# se stiamo salendo
					is_on_floor = false
				else:
					var up = Vector3(0.0, 1.0, 0.0)
					var end_pos = target_global_origin - (up * 0.1)
					var intersects = state.intersect_ray(target_global_origin, end_pos)
					if intersects.empty():
						is_on_floor = false
					else:
						# siamo entrati in collisione con il pavimento o con un muro?
						floor_normal = intersects["normal"]
						var dot = floor_normal.dot(up)
						if dot > 0.9:
							is_on_floor = true
						else:
							is_on_floor = false
						
						collided_at = intersects["position"]
				
				cast_length += (collided_at - target_global_origin).length()
				target_global_origin = collided_at
				hit_something = true
				break
		
		$Teleport.get_surface_material(0).set_shader_param("scale_t", 1.0 / strength)
		$Teleport.get_surface_material(0).set_shader_param("ws", ws)
		$Teleport.get_surface_material(0).set_shader_param("length", cast_length)
		if hit_something:
			var color = can_teleport_color
			var normal = Vector3(0.0, 1.0, 0.0)
			if is_on_floor:
				# se siamo a terra orientiamo nuovamente il nostro target affinchè corrisponda
				normal = floor_normal
				can_teleport = true
			else:
				can_teleport = false
				color = cant_teleport_color
			
			# controlla l'asse per vedere se dobbiamo ruotare
			teleport_rotation += (delta * controller.get_joystick_axis(0) * -4.0)
			
			var target_basis = Basis()
			target_basis.z = Vector3(teleport_global_transform.basis.z.x, 0.0, teleport_global_transform.basis.z.z).normalized()
			target_basis.y = normal
			target_basis.x = target_basis.y.cross(target_basis.z)
			target_basis.z = target_basis.x.cross(target_basis.y)
			
			target_basis = target_basis.rotated(normal, teleport_rotation)
			last_target_transform.basis = target_basis
			last_target_transform.origin = target_global_origin + Vector3(0.0, 0.02, 0.0)
			$Target.global_transform = last_target_transform

			$Teleport.get_surface_material(0).set_shader_param("mix_color", color)
			$Target.get_surface_material(0).albedo_color = color
			$Target.visible = can_teleport
		else:
			can_teleport = false
			$Target.visible = false
			$Teleport.get_surface_material(0).set_shader_param("mix_color", no_collision_color)
	elif is_teleporting:
		if can_teleport:
			
			var new_transform = last_target_transform
			new_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			new_transform.basis.x = new_transform.basis.y.cross(new_transform.basis.z).normalized()
			new_transform.basis.z = new_transform.basis.x.cross(new_transform.basis.y).normalized()
			
			var camera_node = origin_node.get_node("ARVRCamera")
			var cam_transform = camera_node.transform
			var user_feet_transform = Transform()
			user_feet_transform.origin = cam_transform.origin
			user_feet_transform.origin.y = 0 # il personaggio tocca il pavimento, ma deve avere la stessa x e z della camera
			
			user_feet_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			user_feet_transform.basis.x = user_feet_transform.basis.y.cross(cam_transform.basis.z).normalized()
			user_feet_transform.basis.z = user_feet_transform.basis.x.cross(user_feet_transform.basis.y).normalized()
			
		#	origin_node.global_transform = new_transform * user_feet_transform.inverse()
			player.global_transform = new_transform * user_feet_transform.inverse()
		
		is_teleporting = false;
		$Teleport.visible = false
		$Target.visible = false

