extends Area

func _ready():
	var animation = get_node("../AnimationPlatform") 
	animation = false
	$Area.connect("body_entered", self, "collided")

func collided(body):
	if animation == false:
		if body.has_method("bullet_hit"):
			body.bullet_hit(BULLET_DAMAGE, global_transform)
        hit_something = true