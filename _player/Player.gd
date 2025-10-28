extends CharacterBody3D
class_name Player

# Player API - handles all initialization and component access
@onready var player_api = $PlayerAPI

func _ready():
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Initialize all systems through API
	player_api.initialize_all_systems(self)
	
	# Force apply blue material to player model
	apply_blue_material()

func _input(event):
	player_api.player_input.handle_input(event)

func _physics_process(delta):
	# Handle movement input
	player_api.player_input.process_movement_input()
	
	# Handle movement
	if player_api.player_state.is_noclip_active():
		player_api.player_state.handle_noclip_movement(delta)
	else:
		player_api.player_movement.physics_process(delta)
	
	# Check for height-based respawn
	check_height_respawn()
	
	# Update camera
	player_api.player_camera.update_head_bob(delta)
	player_api.player_camera.update_camera_position(delta)
	
	# Update guns
	player_api.gun_manager.update_guns(delta)

# API functions for other systems to access player components
func get_camera() -> Camera3D:
	return player_api.get_camera()

func get_camera_controller() -> Node3D:
	return player_api.get_camera_controller()

func check_height_respawn():
	# Check if player has fallen too far or risen too high
	var current_height = global_position.y
	if current_height <= -1000.0 or current_height >= 1000.0:
		print("Player reached extreme height (", current_height, "), teleporting back to spawn...")
		player_api.player_health.teleport_to_spawn()

func apply_blue_material():
	# Force apply blue material to ensure visibility
	var blue_material = StandardMaterial3D.new()
	blue_material.albedo_color = Color(0, 0.3, 1, 1)  # Bright blue
	blue_material.flags_unshaded = true
	blue_material.flags_do_not_receive_shadows = true
	blue_material.emission_enabled = true
	blue_material.emission = Color(0, 0.2, 0.8, 1)  # Blue glow
	blue_material.flags_transparent = false
	
	# Apply to player model
	var mesh_instance = $MeshInstance3D
	var player_model = mesh_instance.get_node("PlayerModel")
	if player_model:
		player_model.material_override = blue_material
		player_model.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		print("Applied blue material to player model")
		print("Player model material: ", player_model.material_override)
	else:
		print("Could not find PlayerModel node")
