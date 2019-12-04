extends Spatial


func _physics_process(delta):
	# manteniamoci in linea con la nostra fotocamera
	var new_transform = get_node("../ARVRCamera").transform
	
	var new_basis = Basis()
	new_basis.z = Vector3(new_transform.basis.z.x, 0.0, new_transform.basis.z.z).normalized()
	if new_basis.z.length() > 0.5:
		new_basis.y - Vector3(0.0, 1.0, 0.0)
		new_basis.x = new_basis.y.cross(new_basis.z)
		new_transform.basis = new_basis
	
		transform = new_transform
	else:
		#stiamo guardando verso l'alto o verso il basso
		pass
