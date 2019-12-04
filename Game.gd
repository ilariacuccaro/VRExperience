extends Spatial

func _ready():
    var VR = ARVRServer.find_interface("OpenVR")
    if VR and VR.initialize():
        get_viewport().arvr = true
        get_viewport().hdr = false
        get_viewport().rgba8_out = true

        OS.vsync_enabled = false
        Engine.target_fps = 90
		
        $Player/ARVROrigin/Right_Hand.connect("button_pressed", $Player/ARVROrigin/HUD_Anchor/Settings_VR, "_on_Right_Hand_button_pressed")
