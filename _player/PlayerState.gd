extends Node
class_name PlayerState

signal state_changed(state_name: String, enabled: bool)

@onready var player: Player = get_parent()

# State flags
var noclip_enabled: bool = false
var invincibility_enabled: bool = false

# Input actions for state toggles
const NOCLIP_ACTION = "noclip"
const INVINCIBILITY_ACTION = "invincibility"

func _ready():
	print("PlayerState initialized")

func _input(event):
	# Handle state toggle inputs
	if event.is_action_pressed(NOCLIP_ACTION):
		toggle_noclip()
	elif event.is_action_pressed(INVINCIBILITY_ACTION):
		toggle_invincibility()

func toggle_noclip():
	noclip_enabled = !noclip_enabled
	apply_noclip_state()
	state_changed.emit("noclip", noclip_enabled)
	
	var status = "ON" if noclip_enabled else "OFF"
	print("Noclip: ", status)

func apply_noclip_state():
	if noclip_enabled:
		# Disable physics
		player.collision_layer = 0
		player.collision_mask = 0
		# Switch to third person in noclip so you can see your character
		player.player_api.player_camera.set_camera_mode(PlayerCamera.CameraMode.THIRD_PERSON)
		print("Noclip enabled - switched to third person camera")
	else:
		# Re-enable physics
		player.collision_layer = 1
		player.collision_mask = 1
		# Switch back to first person when exiting noclip
		player.player_api.player_camera.set_camera_mode(PlayerCamera.CameraMode.FIRST_PERSON)
		print("Noclip disabled - switched to first person camera")

func toggle_invincibility():
	invincibility_enabled = !invincibility_enabled
	state_changed.emit("invincibility", invincibility_enabled)
	
	var status = "ON" if invincibility_enabled else "OFF"
	print("Invincibility: ", status)

func handle_noclip_movement(delta: float):
	if not noclip_enabled:
		return
	
	var input_vector = Vector3.ZERO
	var camera_controller = player.player_api.camera_controller
	
	if Input.is_action_pressed("move_forward"):
		input_vector -= camera_controller.transform.basis.z
	if Input.is_action_pressed("move_backward"):
		input_vector += camera_controller.transform.basis.z
	if Input.is_action_pressed("move_left"):
		input_vector -= camera_controller.transform.basis.x
	if Input.is_action_pressed("move_right"):
		input_vector += camera_controller.transform.basis.x
	if Input.is_action_pressed("jump"):
		input_vector += Vector3.UP
	if Input.is_action_pressed("crouch"):
		input_vector -= Vector3.UP
	
	input_vector = input_vector.normalized()
	
	var noclip_speed = 10.0  # NOCLIP_SPEED constant
	if player.player_api.player_movement.is_running:
		noclip_speed *= 2.0
	
	player.position += input_vector * noclip_speed * delta

func is_noclip_active() -> bool:
	return noclip_enabled

func is_invincible() -> bool:
	return invincibility_enabled

func get_state_info() -> Dictionary:
	return {
		"noclip": noclip_enabled,
		"invincibility": invincibility_enabled,
		"noclip_text": "NOCLIP: ON" if noclip_enabled else "NOCLIP: OFF",
		"invincibility_text": "INVINCIBLE: ON" if invincibility_enabled else "INVINCIBLE: OFF"
	}

func set_noclip(enabled: bool):
	if noclip_enabled != enabled:
		noclip_enabled = enabled
		apply_noclip_state()
		state_changed.emit("noclip", noclip_enabled)

func set_invincibility(enabled: bool):
	if invincibility_enabled != enabled:
		invincibility_enabled = enabled
		state_changed.emit("invincibility", invincibility_enabled)

# Debug functions
func enable_god_mode():
	set_noclip(true)
	set_invincibility(true)
	print("God mode enabled!")

func disable_god_mode():
	set_noclip(false)
	set_invincibility(false)
	print("God mode disabled!")