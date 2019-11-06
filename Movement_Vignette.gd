extends ColorRect

var controller_one
var controller_two

func _ready():
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
    yield(get_tree(), "idle_frame")
#otteniamo l'interfaccia VR corrente 
    var interface = ARVRServer.get_primary_interface()
    rect_size = interface.get_render_targetsize() # modifichiamo le dimensioni 
    rect_position = Vector2(0, 0) #e la posizione del nodo ColorRect in modo che copra l'intera vista in VR

    controller_one = get_parent().get_node("Right_Controller") 
    controller_two = get_parent().get_node("Left_Controller")

    visible = false 


func _process(delta):

    if not controller_one or not controller_two:
        return
# se uno dei controller sposta il giocatore rendiamo visibile la vignetta
    if controller_one.directional_movement or controller_two.directional_movement:
        visible = true
    else:
        visible = false
