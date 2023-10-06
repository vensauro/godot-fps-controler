extends Node3D

@export_enum("forward", "backward") var direction := "forward"
@export var force = 15

func _physics_process(delta):
	var force_direction = Vector3.FORWARD if direction == "forward" else Vector3.BACK
	$RigidBody3D.apply_force(force_direction * force * delta)
	
func _process(delta):
	pass
	# translate(Vector3(0, 0, 1 if direction == "forward" else -1) * delta)



