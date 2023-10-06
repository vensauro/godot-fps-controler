extends CharacterBody3D

var tween: Tween
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var camera_3d = $CameraPivot/Camera3D
@onready var crouching_shape_cast = $CrouchingShapeCast

@onready var capsule: CapsuleShape3D = $CollisionShape3D.shape 
@onready var mesh: CapsuleMesh = $MeshInstance3D.mesh
@onready var camera_pivot = $CameraPivot
@onready var debug_info = $PlayerDebugInfo/Panel/MarginContainer/VBoxContainer/Label
@onready var stair_collision_shape: CollisionShape3D = $StairCollisionShape
@onready var stair_separation_ray: SeparationRayShape3D = stair_collision_shape.shape

@export var stair_height := .3

@export var show_debug_info := false
@export var camera_on_debug := false

@export var tilt_upper_limit := PI / 2
@export var tilt_lower_limit := -(PI / 2)

@export var speed_smooth = .8
@export var walking_speed = 5.0
@export var crouch_speed = 2.0
@export var slide_speed = 6.5
@export var sprint_multiplier = 1.5

var running_squared = pow(walking_speed * sprint_multiplier, 2)


@export var slide_time = .6
var slide_actual_time = slide_time

@export var jump_velocity = 4.5

@export var mouse_sensitivity = 0.002
var mouse_captured = false

var camera_height = 1.8
@onready var character_height = capsule.height
var crouch_decrease_percent = .44
var crouch_duration = .8
var final_height = 1 - crouch_decrease_percent

var is_running = false
var is_crouching = false
var is_sliding = false

func _ready():
	camera_pivot.position.z = 2.5 if camera_on_debug else 0.0

func _physics_process(delta):
	is_running = Input.is_action_pressed("sprint")
	
	DebugDraw3D.draw_line(
		stair_collision_shape.position,
		stair_collision_shape.position + Vector3.DOWN * stair_separation_ray.length,
		Color.BLACK,
#		1
	)

	if Input.is_action_pressed("crouch"):
		is_crouching = true
		crouching_shape_cast.enabled = true
		var tween_duration = crouch_duration / 4 if is_running else crouch_duration

		tween = get_tree().create_tween()
		tween.set_parallel(true)

		var change_height = character_height * final_height
#		stair_separation_ray.length = .2
#		stair_collision_shape.position.y = 2
		tween.tween_property(capsule, "height", change_height, tween_duration)
		tween.tween_property(mesh, "height", change_height, tween_duration)
		tween.tween_property(camera_pivot, "position:y", camera_height * final_height, tween_duration)
	elif !crouching_shape_cast.is_colliding() and crouching_shape_cast.enabled:
		is_crouching = false
		crouching_shape_cast.enabled = false

		tween = get_tree().create_tween()
		tween.set_parallel(true)

#		tween.tween_property(stair_collision_shape, "position:y", character_height, crouch_duration)
#		tween.tween_property(stair_separation_ray, "length", character_height, crouch_duration)
#		tween.tween_property(stair_separation_ray, "height", character_height, crouch_duration)
		tween.tween_property(capsule, "height", character_height, crouch_duration)
		tween.tween_property(mesh, "height", character_height, crouch_duration)
		tween.tween_property(camera_pivot, "position:y", camera_height, crouch_duration)


	if velocity.length_squared() >= running_squared - 1 \
		and Input.is_action_pressed("crouch") and is_on_floor():
		is_sliding = true

	if slide_actual_time <= 0:
		is_sliding = false

	if slide_actual_time <= slide_time and !is_crouching:
		is_sliding = false
		slide_actual_time = slide_time

	var can_slide = is_sliding and slide_actual_time > 0

	var speed: float = \
		slide_speed if can_slide else \
		crouch_speed if is_crouching and is_on_floor() else \
		walking_speed
		
	if is_running:
		speed *= sprint_multiplier

	if can_slide:
		slide_actual_time -= delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		var x_velocity = direction.x * speed
		var z_velocity = direction.z * speed

		velocity.x = move_toward(velocity.x, x_velocity, speed_smooth)
		velocity.z = move_toward(velocity.z, z_velocity, speed_smooth)
	else:
		velocity.x = move_toward(velocity.x, 0, speed_smooth)
		velocity.z = move_toward(velocity.z, 0, speed_smooth)

	for index in range(get_slide_collision_count()):
		var collision = get_slide_collision(index)
		_act_on_collision(collision)

	move_and_slide()

	_show_debug_info(is_on_floor())

func _show_debug_info(on_floor):
	if show_debug_info:
		$PlayerDebugInfo.visible = true
	else:
		$PlayerDebugInfo.visible = false
		return

	var debug_text = [
		"velocity²: {0}",
		"is_running: {1}",
		"is_crouching: {2}",
		"is_sliding: {3}",
		"slide_time: {4}",
		"is_on_floor: {5}",
	]

	debug_info.text = "\n".join(debug_text) \
		.format([
			velocity.length_squared(),
			is_running,
			is_crouching,
			is_sliding,
			slide_actual_time,
			on_floor,
		])

func _act_on_collision(collision: KinematicCollision3D):
	var collider = collision.get_collider()

	if collider == null || collider is StaticBody3D:
		return

	if collider is Door and collider is RigidBody3D:
		var door = (collider as RigidBody3D)
		door.apply_central_impulse(-1 * collision.get_normal() * .3 * velocity.length())

func _update_camera(mouse_relative: Vector2):
	if !is_sliding:
		rotate_y(-mouse_relative.x * mouse_sensitivity)
	camera_3d.rotate_x(-mouse_relative.y * mouse_sensitivity)
	camera_3d.rotation.x = clampf(camera_3d.rotation.x, tilt_lower_limit, tilt_upper_limit)

func _unhandled_input(event):
	if event.is_action_pressed("ui_home"):
		camera_pivot.position.z = 2.5 if camera_on_debug else 0.0
		camera_on_debug = !camera_on_debug
		
	
	if event.is_action_pressed("quit"):
		get_tree().quit()
	
	if event is InputEventMouseMotion:
		_update_camera(event.relative)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
		mouse_captured = !mouse_captured


