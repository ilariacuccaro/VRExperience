extends ARVRController

onready var grab_area = $Area
onready var grab_raycast = $GrabCast
onready var grab_pos_node = $Grab_Pos
onready var hand_mesh = $Hand #usata per rappresentare la mano del giocatore
onready var teleport_raycast = $RayCast #utilizzato per il calcolo della posizione del teletrasporto

var controller_velocity = Vector3(0, 0, 0) #velocità a cui si sta muovendo il controller
var prior_controller_position = Vector3(0, 0, 0) # posizione precedente del controller, servirà per calcolare la velocità del controller
var prior_controller_velocities = [] #velocità di 1/3 di secondo
var held_object = null #oggetto attualmente trattenuto
var held_object_data = {"mode":RigidBody.MODE_RIGID, "layer":1, "mask":1} #dati dell'oggetto attualmente trattenuto

var grab_mode = "AREA" #nodo Area utilizzato per afferrare gli oggetti
var teleport_pos #posizione verso la quale viene puntato il teletrasporto Raycast
var teleport_mesh #mesh utilizzata per rappresentare la posizione del teletrasporto
var teleport_button_down #variabile per tracciare se il pulsante di teletrasporto viene premuto

const CONTROLLER_DEADZONE = 0.65 #zona morta
const MOVEMENT_SPEED = 1.5 #velocità alla quale il giocatore si muove
var directional_movement = false #valore booleano per tracciare se il giocatore si sta muovendo usando il controller

onready var animazione = get_node("../../World/MeshPlatformer/AnimationP")

func _ready():
    teleport_mesh = get_tree().root.get_node("Game/Teleport_Mesh") #otteniamo il nodo Raycast/Mesh del teletrasporto e lo assegniamo a teleport_raycast
    teleport_button_down = false

    grab_mode = "AREA"
    get_node("Sleep_Area").connect("body_entered", self, "sleep_area_entered")
    get_node("Sleep_Area").connect("body_exited", self, "sleep_area_exited")

    connect("button_pressed", self, "button_pressed")
    connect("button_release", self, "button_released")
    animazione.stop() 

func _physics_process(delta):
 
  #  process_input(delta)
    if teleport_button_down: #controlliamo se il pulsante di teletrasporto è inattivo
        teleport_raycast.force_raycast_update() #forziamo l' aggiornamento del teletrasporto Raycast
        if teleport_raycast.is_colliding():
            if teleport_raycast.get_collider() is StaticBody: # controlliamo se il corpo di collisione con cui Raycast sta entrando in collisione è uno StaticBody
                if teleport_raycast.get_collision_normal().y >= 0.85: #verifichiamo se il valore y restituito da Raycast è >0.85
                    teleport_pos = teleport_raycast.get_collision_point() #impostiamo il punto di collisione e spostiamo la mesh di teletrasporto su teleport_pos
                    teleport_mesh.global_transform.origin = teleport_pos
            elif teleport_raycast.get_collider() is KinematicBody: 
                if "MeshPlatformer": #se entriamo in contatto con la piattaforma
	               # get_node("../../World/MeshPlatformer1").visible = false
	                animazione.play("AnimationPlatform") #facciamo partire l'animazione

    # Controller velocity
    # --------------------
    if get_is_active(): #Se l'ARVRController è attivo
        controller_velocity = Vector3(0, 0, 0) 

        if prior_controller_velocities.size() > 0:
            for vel in prior_controller_velocities:
                controller_velocity += vel
             #otteniamo la velocità media
            controller_velocity = controller_velocity / prior_controller_velocities.size()
   # calcoliamo la velocità dalla posizione originale a quella in cui si trova attualmente il controller
        prior_controller_velocities.append((global_transform.origin - prior_controller_position) / delta)
   #aggiorniamo la velocità del controller
        controller_velocity += (global_transform.origin - prior_controller_position) / delta
        prior_controller_position = global_transform.origin #eseguiamo l' aggiornamento alla posizione corrente
        
#se abbiamo velocità maggiori di 1/3 al secondo 
        if prior_controller_velocities.size() > 30:
            prior_controller_velocities.remove(0)  # rimuoviamo la velocità più vecchia da prior_controller_velocities
			
            if held_object:
                var held_scale = held_object.scale
                held_object.global_transform = grab_pos_node.global_transform
                held_object.scale = held_scale
  # convertiamo i valori degli assi in variabili Vector2 , in modo da poterli elaborare
    var trackpad_vector = Vector2(-get_joystick_axis(1), get_joystick_axis(0))
    var joystick_vector = Vector2(-get_joystick_axis(5), get_joystick_axis(4))
 #consideriamo le zone morte sia sul trackpad che sul joystick
    if trackpad_vector.length() < CONTROLLER_DEADZONE:
        trackpad_vector = Vector2(0, 0)
    else:
        trackpad_vector = trackpad_vector.normalized() * ((trackpad_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))

    if joystick_vector.length() < CONTROLLER_DEADZONE:
        joystick_vector = Vector2(0, 0)
    else:
        joystick_vector = joystick_vector.normalized() * ((joystick_vector.length() - CONTROLLER_DEADZONE) / (1 - CONTROLLER_DEADZONE))
#otteniamo i vettori direzionali poter spostare il giocatore in avanti/indietro e a destra/sinistra, a seconda di dove stia guardando
    var forward_direction = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
    var right_direction = get_parent().get_node("Player_Camera").global_transform.basis.x.normalized()
# calcoliamo di quanto si sposterà il giocatore sommando insieme i vettori del trackpad e del joystick e normalizzandoli
    var movement_vector = (trackpad_vector + joystick_vector).normalized()

    var movement_forward = forward_direction * movement_vector.x * delta * MOVEMENT_SPEED #calcoliamo lo spostamento avanti/indietro
    var movement_right = right_direction * movement_vector.y * delta * MOVEMENT_SPEED #calcoliamo0 lo spostamento destra/sinistra
#rimuoviamo il movimento sull'asse Y 
    movement_forward.y = 0
    movement_right.y = 0

    if movement_right.length() > 0 or movement_forward.length() > 0:
        get_parent().translate(movement_right + movement_forward) #spostiamo il giocatore 
        directional_movement = true 
    else:
        directional_movement = false
    # --------------------
	
func button_pressed(button_index):
   if button_index == 15: #se è stato premuto il pulsante di attivazione
        if held_object: #se ho un oggetto trattenuto
            if held_object.has_method("interact"): #interagiremo con l'oggetto 
                held_object.interact() 
 #Se il controller non tiene in mano un oggetto, verifichiamo che la mesh del teletrasporto non sia visibile
        else:
            if not teleport_mesh.visible and not held_object: #se la mesh del teletrasporto non è visibile
                teleport_button_down = true
                teleport_mesh.visible = true
                teleport_raycast.visible = true

   if button_index == 2: #se premiamo il pulsante per afferrare/lasciare  un oggetto
        if teleport_button_down: # se il giocatore sta tentando di teletrasportarsi
            return

        if not held_object: # se il controller non sta tenendo un oggetto 
            var rigid_body = null
            if grab_mode == "AREA": #se sto usando la modalità Area per afferrare 
                var bodies = grab_area.get_overlapping_bodies() #otteniamo tutti i corpi sovrapposti all'area
                if len(bodies) > 0:
                    for body in bodies:
                        if body is RigidBody: #vediamo se è un corpo rigido
                            if not "NO_PICKUP" in body: #Verifichiamo inoltre che tutti i nodi RigidBody nell'area non abbiano una variabile chiamata NO_PICKUP
                                rigid_body = body
                                break

            elif grab_mode == "RAYCAST":
                grab_raycast.force_raycast_update() 
                if grab_raycast.is_colliding(): #controlliamo se il raycast si sta scontrando con qualcosa
                    if grab_raycast.get_collider() is RigidBody and not "NO_PICKUP" in grab_raycast.get_collider():
                        rigid_body = grab_raycast.get_collider()


            if rigid_body:

                held_object = rigid_body #abbiamo preso un corpo rigido

                held_object_data["mode"] = held_object.mode
                held_object_data["layer"] = held_object.collision_layer
                held_object_data["mask"] = held_object.collision_mask

                held_object.mode = RigidBody.MODE_STATIC
                held_object.collision_layer = 0
                held_object.collision_mask = 0

                hand_mesh.visible = false
                grab_raycast.visible = false

                if held_object.has_method("picked_up"):
                    held_object.picked_up()
                if "controller" in held_object:
                    held_object.controller = self


        else:

            held_object.mode = held_object_data["mode"]
            held_object.collision_layer = held_object_data["layer"]
            held_object.collision_mask = held_object_data["mask"]

            held_object.apply_impulse(Vector3(0, 0, 0), controller_velocity)

            if held_object.has_method("dropped"): #Se il RigidBody precedentemente detenuto ha una funzione chiamata dropped
                held_object.dropped() # la chiamiamo

            if "controller" in held_object:
                held_object.controller = null

            held_object = null  #non ho può oggetti
            hand_mesh.visible = true  #la mano è ora visibile

            if grab_mode == "RAYCAST":
                grab_raycast.visible = true

    # If the menu button is pressed...
 #   if button_index == 1:
 #       if grab_mode == "AREA":
 #           grab_mode = "RAYCAST"
#
#            if not held_object:
 #              grab_raycast.visible = true
#        elif grab_mode == "RAYCAST":
#            grab_mode = "AREA"
#            grab_raycast.visible = false

func button_released(button_index):

    # If the trigger button is released...
    if button_index == 15:

        if teleport_button_down:

            if teleport_pos and teleport_mesh.visible:
                var camera_offset = get_parent().get_node("Player_Camera").global_transform.origin - get_parent().global_transform.origin #la camera si sposta in base all'origine
                camera_offset.y = 0 #non teniamo conto dell'altezza del giocatore

                get_parent().global_transform.origin = teleport_pos - camera_offset
#ripristiniamo tutte le variabili relative al teletrasporto in modo che il controllore debba acquisirne di nuove prima di teletrasportarsi di nuovo
            teleport_button_down = false
            teleport_mesh.visible = false
            teleport_raycast.visible = false
            teleport_pos = null
			
func sleep_area_entered(body):
    if "can_sleep" in body:
        body.can_sleep = false
        body.sleeping = false

func sleep_area_exited(body):
    if "can_sleep" in body:
        body.can_sleep = true

#func process_input(delta):
 #   var velocity = Vector3()
  #  if(Input.is_action_pressed("ui_down")):
  #      velocity.z=-1
  #      var down_d = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
  #  if(Input.is_action_pressed("ui_up")):
  #       velocity.z=1
  #       var up_d = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
  #  if(Input.is_action_pressed("ui_left")):
  #      velocity.x=-1
  #      var left_d = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
  #  if(Input.is_action_pressed("ui_right")):
  #      velocity.x=1
  #      var right_d = get_parent().get_node("Player_Camera").global_transform.basis.z.normalized()
  #  var personaggio = get_node("../../KinematicBody")
  #  personaggio.move_and_slide(velocity*delta*SPEED)
