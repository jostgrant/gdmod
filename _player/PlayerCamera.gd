extends Node
class_name PlayerCamera

# Camera settings
const MOUSE_SENSITIVITY = 0.002
const HEAD_BOB_FREQUENCY = 2.0
const HEAD_BOB_AMPLITUDE = 0.08
const CAMERA_SMOOTHING = 8.0

# Camera modes
enum CameraMode { FIRST_PERSON, THIRD_PERSON }
var current_camera_mode = CameraMode.THIRD_PERSON

# Third person camera settings
const THIRD_PERSON_DISTANCE = 3.0
const THIRD_PERSON_HEIGHT = 1.0

# Head bobbing
var head_bob_time = 0.0
var head_bob_vector = Vector2.ZERO

# References
var player: CharacterBody3D
var camera_controller: Node3D
var camera: Camera3D
var player_movement: Node
var player_state: PlayerState

func initialize(p: CharacterBody3D, cc: Node3D, c: Camera3D, pm: Node, ps: PlayerState):
	player = p
	camera_controller = cc
	camera = c
	player_movement = pm
	player_state = ps
	
	# Set initial camera position (third person to see blue character)
	set_camera_mode(CameraMode.THIRD_PERSON)

func handle_mouse_input(event: InputEventMouseMotion):
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
		
	# Horizontal rotation (Y-axis)
	player.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Vertical rotation (X-axis)
	camera_controller.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	camera_controller.rotation.x = clamp(camera_controller.rotation.x, -PI/2, PI/2)

func update_head_bob(delta):
	if not player.is_on_floor() or player_state.is_noclip_active():
		return
	
	var horizontal_velocity = Vector2(player.velocity.x, player.velocity.z)
	var speed = horizontal_velocity.length()
	
	if speed > 0.1:
		head_bob_time += delta * HEAD_BOB_FREQUENCY * (speed / 3.5)  # WALK_SPEED constant
		
		var bob_amplitude = HEAD_BOB_AMPLITUDE
		if player_movement.is_running:
			bob_amplitude *= 1.5
		elif player_movement.is_crouching:
			bob_amplitude *= 0.5
		
		head_bob_vector.y = sin(head_bob_time) * bob_amplitude
		head_bob_vector.x = sin(head_bob_time * 0.5) * bob_amplitude * 0.3
	else:
		head_bob_time = 0.0
		head_bob_vector = Vector2.ZERO

func update_camera_position(delta):
	if player_state.is_noclip_active():
		return
	
	if current_camera_mode == CameraMode.FIRST_PERSON:
		# Apply head bobbing for first person
		var target_position = camera.position
		target_position.x = head_bob_vector.x
		target_position.y = head_bob_vector.y
		
		camera.position = camera.position.lerp(target_position, CAMERA_SMOOTHING * delta)
	else:
		# Third person camera follows behind the player
		var target_position = Vector3(0, THIRD_PERSON_HEIGHT, THIRD_PERSON_DISTANCE)
		camera.position = camera.position.lerp(target_position, CAMERA_SMOOTHING * delta)

func set_camera_mode(mode: CameraMode):
	current_camera_mode = mode
	
	if mode == CameraMode.FIRST_PERSON:
		camera_controller.position = Vector3(0, 1.6, 0)
		camera.position = Vector3.ZERO
		# Hide player model in first person
		if player.player_api.mesh_instance:
			player.player_api.mesh_instance.visible = false
	else:
		camera_controller.position = Vector3(0, 1.6, 0)
		camera.position = Vector3(0, THIRD_PERSON_HEIGHT, THIRD_PERSON_DISTANCE)
		# Show player model in third person
		if player.player_api.mesh_instance:
			player.player_api.mesh_instance.visible = true

func toggle_camera_mode():
	if current_camera_mode == CameraMode.FIRST_PERSON:
		set_camera_mode(CameraMode.THIRD_PERSON)
	else:
		set_camera_mode(CameraMode.FIRST_PERSON)

func get_camera_mode() -> CameraMode:
	return current_camera_mode

# Getter functions for other systems
func get_camera() -> Camera3D:
	return camera

func get_camera_controller() -> Node3D:
	return camera_controller