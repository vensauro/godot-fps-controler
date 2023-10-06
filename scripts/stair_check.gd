extends ShapeCast3D


@export var stair_height := 1.0
@export var player: CharacterBody3D
@export var player_collider: CollisionShape3D

enum Direction {
	UP, FORWARD, DOWN
}
@export var direction:Direction

signal colliding_up
signal colliding_forward
signal colliding_down

# if direction == Direction.UP:

func _physics_process1(delta):
	shape.height = player_collider.shape.height
	var up_position = Vector3(0, 1 + stair_height, 0)
	var forward_position = (player.velocity * delta) * player.transform.basis + up_position
	var down_position = forward_position + Vector3.UP * -stair_height

	if is_colliding() and direction == Direction.UP:
		position = up_position
		print("collision up")
		colliding_up.emit()
		DebugDraw3D.draw_sphere(collision_result[0]["point"], .1, Color.BLUE_VIOLET, 10)
		return false
		
	if direction == Direction.FORWARD:
		position = forward_position
		DebugDraw3D.draw_sphere(forward_position, .1, Color.AQUAMARINE, 10)
		# $MeshInstance3D.position = forward_position
		if is_colliding():
			print("collision forward")
			DebugDraw3D.draw_sphere(collision_result[0]["point"], .1, Color.AQUAMARINE, 10)
			
			colliding_forward.emit()
			return false

	if direction == Direction.DOWN:
		position = down_position
		DebugDraw3D.draw_sphere(down_position, .1, Color.BROWN, 10)
		if is_colliding():
			print("collision down")
			
			colliding_down.emit()
			return true

	return false
	

func _process_stair_animation(delta):
	var tween = get_tree().create_tween()

	var tween_v = Vector3(0, 1, 0)
	tween.tween_property(self, "position", tween_v, 1)

	tween_v.y += stair_height
	tween.tween_property(self, "position", tween_v, 1)

	tween_v += player.velocity * player.global_transform.basis
	tween.tween_property(self, "position", tween_v, 1)

	tween_v.y -= stair_height
	tween.tween_property(self, "position", tween_v, 1)


