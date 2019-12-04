extends Spatial


func _ready():
	pass 
	
func _on_Right_Hand_button_pressed( button ):
	if (button == 1):
		visible = not(visible)
		get_node("../../Right_Hand/Function_pointer").set_enabled(visible)