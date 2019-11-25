extends ARVRController

# La velocità alla quale si sta muovendo il controller (calcolata usando i frame della fisica)
var controller_velocity = Vector3(0,0,0)
# La posizione precedente del controller (utilizzata per calcolare la velocità)
var prior_controller_position = Vector3(0,0,0)
# Le ultime 30 velocità calcolate (1/3 di secondo di calcoli di velocità, supponendo che il gioco funzioni a 90 FPS)
var prior_controller_velocities = []

# L'oggetto attualmente trattenuto, se ce n'è uno
var held_object = null
# I dati RigidBody dell'oggetto attualmente trattenuto, utilizzati per ripristinare l'oggetto quando non lo tiene più
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1}

# Nodo Area utilizzato per afferrare oggetti.
var grab_area
# Nodo Raycast utilizzato per afferrare oggetti.
var grab_raycast
# Modalità di acquisizione attuale
var grab_mode = "AREA"
# 
# Posizione in cui si trovano gli oggetti trattenuti
var grab_pos_node

# Maglia della mano, usata per rappresentare la mano del giocatore quando non tengono nulla.
var hand_mesh

var teleport_pos # Posizione a cui è indirizzato il teletrasporto 
var teleport_mesh # Mesh utilizzata per rappresentare la posizione del teletrasporto
var teleport_button_down # Variabile per tracciare se il pulsante del teletrasporto è abbassato 
var teleport_raycast # Raycast del teletrasporto.

# Zona morta sia per il trackpad che per il joystick
const CONTROLLER_DEADZONE = 0.65

# Velocità a cui il giocatore si muove quando si muove con il trackpad
const MOVEMENT_SPEED = 1.5

# Valore booleano per tracciare se il giocatore si sta muovendo usando il controller
# necessario per l'effetto vignetta che mostrato solo quando il giocatore si sta muovendo
var directional_movement = false

func _ready():
	# Ottieni i nodi di teletrasporto
	teleport_raycast = get_node("RayCast")
	teleport_mesh = get_tree().root.get_node("Game/Teleport_Mesh")
	# Pulsante teletrasporto impostato su falso
	teleport_button_down = false
	
	# Ottiene i nodi correlati grab
	grab_area = get_node("Area")
	grab_raycast = get_node("GrabCast")
	grab_pos_node = get_node("Grab_Pos")
	grab_mode = "AREA"
	
	# Collega i segnali dell'area di sonno (dove i RigidBodies non possono dormire quando sono vicini al lettore)
	get_node("Sleep_Area").connect("body_entered", self, "sleep_area_entered")
	get_node("Sleep_Area").connect("body_exited", self, "sleep_area_exited")
	# Ottiene la mesh della mano
	hand_mesh = get_node("Hand")
	# Connessione button VR
	connect("button_pressed", self, "button_pressed")
	connect("button_release", self, "button_released")


func _physics_process(delta):
	
	# Aggiorna la mesh del teletrasporto se il suo pulsante è abbassato
	if teleport_button_down == true:
		teleport_raycast.force_raycast_update()
		if teleport_raycast.is_colliding():
			# Ci assicuriamo che il teleport_raycast stia entrando in collisione con uno StaticBody 
			if teleport_raycast.get_collider() is StaticBody:
				if teleport_raycast.get_collision_normal().y >= 0.85:
					# Impostiamo teleport_pos sul punto raycast e spostare la mesh del teletrasporto
					teleport_pos = teleport_raycast.get_collision_point()
					teleport_mesh.global_transform.origin = teleport_pos
	
	
	# Velocità Controller 
	# --------------------
	# Aggiorna velocità 
	if get_is_active() == true: # c'è un controller attivo 
		# Ripristina la velocità del controller
		controller_velocity = Vector3(0,0,0)
		# L'uso dei calcoli precedenti offre un'esperienza di lancio/cattura più fluida
		# Aggiungi le velocità dei controller precedenti
		if prior_controller_velocities.size() > 0:
			for vel in prior_controller_velocities:
				controller_velocity += vel
			# Ottieni velocità media
			controller_velocity = controller_velocity / prior_controller_velocities.size()
		# Aggiungere la velocità del controller più recente 
		prior_controller_velocities.append((global_transform.origin - prior_controller_position) / delta)
		# Calcola la velocità usando la posizione precedente del controller
		controller_velocity += (global_transform.origin - prior_controller_position) / delta
		prior_controller_position = global_transform.origin
		# Se abbiamo più di un terzo di secondo di velocità, dovremmo rimuovere il più vecchio
		if prior_controller_velocities.size() > 30:
			prior_controller_velocities.remove(0)
	# --------------------

	#Aggiorna la posizione e la rotazione dell'oggetto trattenuto, se presente
	# A causa dello scale, è necessario memorizzarlo temporaneamente e poi reimpostarlo
#	if held_object != null:
#		var held_scale = held_object.scale
#		held_object.global_transform = grab_pos_node.global_transform
#		held_object.scale = held_scale
	
	#  Movimento direzionale
	# --------------------
	# Conversione assi VR in vettori, sia per trackpad che per joystick
	var trackpad_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
	var joystick_vector = Vector2(-get_joystick_axis(5), get_joystick_axis(4))
	
	# Tiene conto delle zone morte
	if trackpad_vector.length() < CONTROLLER_DEADZONE:
		trackpad_vector = Vector2(0,0)
	else:
		trackpad_vector = trackpad_vector.normalized() * ((trackpad_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	
	if joystick_vector.length() < CONTROLLER_DEADZONE:
		joystick_vector = Vector2(0,0)
	else:
		joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
	#Ottiene vettori direzionali della camera in avanti e a destra
	var forward_direction = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
	var right_direction = get_parent().get_node("Player_Camera").global_transform.basis.x.normalized()
	#Calcola quanto ci spostiamo, sommando sia il trackpad che i vettori del joystick e normalizzandoli
	var movement_vector = (trackpad_vector + joystick_vector).normalized()
	# Calcola fino a che punto ci sposteremo avanti/indietro e a destra / a sinistra, usando i vettori direzionali/locali dello spazio
	var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED
	var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED
	#Rimuovi il movimento sull'asse Y in modo che il giocatore non possa volare/cadere muovendosi
	movement_forward.y = 0
	movement_right.y = 0
	# Muovi il giocatore se c'è qualche movimento avanti/indietro o destra/sinistra
	if (movement_right.length() > 0 or movement_forward.length() > 0):
		get_parent().translate(movement_right + movement_forward)
		directional_movement = true
	else:
		directional_movement = false
	# --------------------

func button_pressed(button_index):
	# Se viene premuto il grilletto
	if button_index == 15:
		# Interagisci con l'oggetto trattenuto, se presente
		if held_object != null:
			if held_object.has_method("interact"):
				held_object.interact()
		# Teletrasportati se non trattieni un oggetto
		else:
			# Assicurarsi che l'altro controller non stia già tentando di teletrasportarsi
			if teleport_mesh.visible == false and held_object == null:
				teleport_button_down = true
				teleport_mesh.visible = true
				teleport_raycast.visible = true
	# Se il pulsante di acquisizione viene premuto
	if button_index == 2:
		# Assicurati che non possiamo raccogliere oggetti durante il tentativo di teletrasporto
		if (teleport_button_down == true):
			return
		# Prendi un RigidBody se non tratteniamo un oggetto
		if held_object == null:
			var rigid_body = null
			
			# Se stiamo usando un'Area per afferrare
			if (grab_mode == "AREA"):
				# Prendi tutti i corpi nell'area di acquisizione, supponendo che ce ne siano
				var bodies = grab_area.get_overlapping_bodies()
				if len(bodies) > 0:
					
					# Controlla se c'è un corpo rigido tra i corpi all'interno dell'area di presa
					for body in bodies:
						if body is RigidBody:
							# Supponendo che non vi sia alcuna variabile chiamata NO_PICKUP in RigidBody
							# Aggiungendo una variabile denominata NO_PICKUP
							# è possibile farlo laddove il RigidBody non possa essere prelevato dai controller
							if !("NO_PICKUP" in body):
								rigid_body = body
								break
			# Stiamo usando il Raycast per afferrare
			elif (grab_mode == "RAYCAST"):
				# Forza l'aggiornamento del raycast
				grab_raycast.force_raycast_update()
				# Controlla se il raycast si sta scontrando
				if (grab_raycast.is_colliding()):
					# Se quello con cui il raycast si scontra è un RigidBody e non ha una variabile chiamata NO_PICKUP, allora possiamo prenderlo
					if grab_raycast.get_collider() is RigidBody and !("NO_PICKUP" in grab_raycast.get_collider()):
						rigid_body = grab_raycast.get_collider()
			
			# Se è stato trovato un RigidBody utilizzando Area o Raycast
			if rigid_body != null:
				# Assegna l'oggetto trattenuto 
				held_object = rigid_body
				# Conservare le informazioni di RigidBody ora detenute
				held_object_data["mode"] = held_object.mode
				held_object_data["layer"] = held_object.collision_layer
				held_object_data["mask"] = held_object.collision_mask
				
				# Facciamo in modo che non possa scontrarsi con nulla
				held_object.mode = RigidBody.MODE_STATIC
				held_object.collision_layer = 0
				held_object.collision_mask = 0
				
				# Rendi invisibile la mesh della mano e grab_raycast
				hand_mesh.visible = false
				grab_raycast.visible = false
				
				# Se il RigidBody ha una funzione chiamata pick_up, la chiamiamo
				if (held_object.has_method("picked_up")):
					held_object.picked_up()
				# Se RigidBody ha una variabile chiamata controller, la assegnamo
				if ("controller" in held_object):
					held_object.controller = self
		
		else:
			
			# Riportiamo i dati RigidBody dell'oggetto trattenuto su ciò che è stato memorizzato
			held_object.mode = held_object_data["mode"]
			held_object.collision_layer = held_object_data["layer"]
			held_object.collision_mask = held_object_data["mask"]
			
			# Applicare un impulso nella direzione della velocità del controller
			held_object.apply_impulse(Vector3(0, 0, 0), controller_velocity)
			
			# Se il RigidBody ha una funzione chiamata drop, allora la chiamiamo
			if held_object.has_method("dropped"):
				held_object.dropped()
			
			#Se RigidBody ha una variabile chiamata controller, viene impostata a null
			if "controller" in held_object:
				held_object.controller = null
			
			# Impostiamo held_object su null poiché questo controller non contiene più nulla
			held_object = null
			# Rendiamo hand_mesh visibile
			hand_mesh.visible = true
			
			# Rendiamo visibile la mesh del grab_raycast se stiamo usando la modalità grab "RAYCAST"
			if (grab_mode == "RAYCAST"):
				grab_raycast.visible = true
			
	# Se si preme il pulsante menu
	if button_index == 1:
		# Passa alla modalità opposta e rendi visibile/invisibile il grab_raycast secondo le necessità
		if grab_mode == "AREA":
			grab_mode = "RAYCAST"
			if held_object == null:
				grab_raycast.visible = true
		elif grab_mode == "RAYCAST":
			grab_mode = "AREA"
			grab_raycast.visible = false


func button_released(button_index):
	# Se il pulsante di attivazione viene rilasciato
	if button_index == 15:
		# Ci assicuriamo che stiamo tentando il teletrasporto
		if (teleport_button_down == true):
			# Se abbiamo una posizione di teletrasporto e la mesh del teletrasporto è visibile, teletrasporta il giocatore
			if teleport_pos != null and teleport_mesh.visible == true:
				# E' necessario capire dove si trova il giocatore in relazione all'origine ARVR
				# In questo modo possiamo teletrasportare il giocatore nella sua posizione corrente 
				var camera_offset = get_parent().get_node("Player_Camera").global_transform.origin - get_parent().global_transform.origin
				# Non vogliamo tenere conto dell'altezza del giocatore.
				# Teletrasporta l'origine ARVR nella posizione di teletrasporto
				get_parent().global_transform.origin = teleport_pos - camera_offset
			
			# Ripristina le variabili relative al teletrasporto
			teleport_button_down = false
			teleport_mesh.visible = false
			teleport_raycast.visible = false
			teleport_pos = null


func sleep_area_entered(body):
	# Quando entra un corpo, controlla se sta dormendo.  Se ha can_sleep, sveglialo
	# Questo fa in modo che i nodi RigidBody si comportino come dovrebbero quando il giocatore è vicino
	if "can_sleep" in body:
		body.can_sleep = false
		body.sleeping = false

func sleep_area_exited(body):
	# Quando un corpo esce, controlla se può dormire. 
	# Se ha can_sleep, assicurati che possa dormire di nuovo per risparmiare sulle prestazioni
	if "can_sleep" in body:
		body.can_sleep = true
	
