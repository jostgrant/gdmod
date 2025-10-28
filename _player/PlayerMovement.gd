extends Node
class_name PlayerMovement

# Movement constants (GMod-inspired values)
const WALK_SPEED = 3.5
const RUN_SPEED = 7.0
const CROUCH_SPEED = 1.5

const JUMP_VELOCITY = 7.5
const AIR_ACCELERATION = 10.0
const GROUND_ACCELERATION = 14.0
const GROUND_DECELERATION = 10.0
const AIR_DECELERATION = 2.0
const MAX_AIR_SPEED = 0.8

# Crouch system
const CROUCH_HEIGHT = 0.9
const STAND_HEIGHT = 1.8
const CROUCH_SPEED_MULTIPLIER = 3.0

# Physics
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var friction = 6.0

# Movement state
var is_running = false
var is_crouching = false
var was_on_floor_last_frame = false

# Input buffering for bunny hopping
var jump_buffer_time = 0.0
const JUMP_BUFFER_WINDOW = 0.1
var coyote_time = 0.0
const COYOTE_TIME_WINDOW = 0.1

# References
var player: CharacterBody3D
var collision_shape: CollisionShape3D
var camera_controller: Node3D
var player_health: PlayerHealth

func initialize(p: CharacterBody3D, cs: CollisionShape3D, cc: Node3D, ph: PlayerHealth):
	player = p
	collision_shape = cs
	camera_controller = cc
	player_health = ph

func handle_input():
	# Running
	is_running = Input.is_action_pressed("run")
	
	# Crouching
	if Input.is_action_pressed("crouch"):
		if not is_crouching:
			start_crouch()
	else:
		if is_crouching:
			try_stand_up()
	
	# Jump buffering
	if Input.is_action_just_pressed("jump"):
		jump_buffer_time = JUMP_BUFFER_WINDOW

func physics_process(delta):
	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	input_dir = input_dir.normalized()
	
	# Calculate movement speed
	var current_speed = WALK_SPEED
	if is_running and not is_crouching:
		current_speed = RUN_SPEED
	elif is_crouching:
		current_speed = CROUCH_SPEED
	
	# Transform input to world space
	var direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Handle jumping with buffering and coyote time
	if jump_buffer_time > 0 and (coyote_time > 0 or player.is_on_floor()):
		player.velocity.y = JUMP_VELOCITY
		jump_buffer_time = 0
		coyote_time = 0
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y -= gravity * delta
	
	# Ground vs air movement
	if player.is_on_floor():
		handle_ground_movement(direction, current_speed, delta)
	else:
		handle_air_movement(direction, current_speed, delta)
	
	player.move_and_slide()
	
	# Handle physics object pushing
	handle_object_pushing()
	
	handle_crouching(delta)
	
	# Update coyote time and jump buffer
	if player.is_on_floor():
		# Check for fall damage when landing
		if not was_on_floor_last_frame and player.velocity.y < -15.0:
			player_health.apply_fall_damage(-player.velocity.y)
		
		coyote_time = COYOTE_TIME_WINDOW
		was_on_floor_last_frame = true
	else:
		coyote_time -= delta
		was_on_floor_last_frame = false
	
	jump_buffer_time -= delta

func handle_ground_movement(direction: Vector3, speed: float, delta: float):
	if direction.length() > 0:
		# Accelerate towards target velocity
		var target_velocity = direction * speed
		player.velocity.x = move_toward(player.velocity.x, target_velocity.x, GROUND_ACCELERATION * delta)
		player.velocity.z = move_toward(player.velocity.z, target_velocity.z, GROUND_ACCELERATION * delta)
	else:
		# Apply friction
		player.velocity.x = move_toward(player.velocity.x, 0, friction * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, friction * delta)

func handle_air_movement(direction: Vector3, speed: float, delta: float):
	if direction.length() > 0:
		# Air strafing mechanics (like in GMod/Source engine)
		var current_horizontal_speed = Vector2(player.velocity.x, player.velocity.z).length()
		var max_speed = speed * MAX_AIR_SPEED
		
		# Only apply air acceleration if we're not exceeding max air speed in the input direction
		var dot_product = Vector2(player.velocity.x, player.velocity.z).normalized().dot(Vector2(direction.x, direction.z))
		
		if current_horizontal_speed < max_speed or dot_product <= 0:
			var target_velocity = direction * speed
			player.velocity.x = move_toward(player.velocity.x, target_velocity.x, AIR_ACCELERATION * delta)
			player.velocity.z = move_toward(player.velocity.z, target_velocity.z, AIR_ACCELERATION * delta)
	else:
		# Minimal air deceleration for momentum preservation
		player.velocity.x = move_toward(player.velocity.x, 0, AIR_DECELERATION * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, AIR_DECELERATION * delta)

func handle_crouching(delta):
	var target_height = STAND_HEIGHT if not is_crouching else CROUCH_HEIGHT
	var current_shape = collision_shape.shape as CapsuleShape3D
	
	current_shape.height = lerp(current_shape.height, target_height, CROUCH_SPEED_MULTIPLIER * delta)
	
	# Adjust collision position
	collision_shape.position.y = current_shape.height / 2.0
	
	# Adjust camera height
	var camera_height = 1.6 if not is_crouching else 1.0
	var target_camera_pos = Vector3(0, camera_height, 0)
	camera_controller.position = camera_controller.position.lerp(target_camera_pos, CROUCH_SPEED_MULTIPLIER * delta)

func start_crouch():
	is_crouching = true

func try_stand_up():
	if can_stand_up():
		is_crouching = false

func can_stand_up() -> bool:
	if not is_crouching:
		return true
	
	# Check if there's space above to stand up
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3(0, CROUCH_HEIGHT/2, 0),
		player.global_position + Vector3(0, STAND_HEIGHT/2 + 0.1, 0)
	)
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func handle_object_pushing():
	# Handle pushing physics objects when colliding
	for collision_index in player.get_slide_collision_count():
		var collision = player.get_slide_collision(collision_index)
		var collider = collision.get_collider()
		
		if collider is RigidBody3D:
			var rigid_body = collider as RigidBody3D
			
			# Calculate push direction (opposite to collision normal)
			var push_direction = -collision.get_normal()
			
			# Get player's movement direction and speed
			var player_horizontal_velocity = Vector3(player.velocity.x, 0, player.velocity.z)
			var velocity_strength = player_horizontal_velocity.length()
			
			# Only push if player is moving with some force
			if velocity_strength < 0.1:
				continue
			
			# Calculate mass-based force multiplier (lighter objects are easier to push)
			var mass_factor = 10.0 / max(rigid_body.mass, 1.0)
			
			# Base push strength
			var push_strength = 8.0
			
			# Adjust force based on player speed and running state
			if is_running:
				push_strength *= 1.5
			
			# Calculate final impulse
			var impulse = push_direction * push_strength * mass_factor * velocity_strength
			
			# Apply impulse to the center of mass for consistent pushing
			rigid_body.apply_central_impulse(impulse)
			
			print("Pushed ", rigid_body.name, " with impulse: ", impulse.length(), " in direction: ", push_direction)