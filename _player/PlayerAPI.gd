extends Node
class_name PlayerAPI

# References to all player components
var player: CharacterBody3D
var camera_controller: Node3D
var camera: Camera3D
var collision_shape: CollisionShape3D
var mesh_instance: MeshInstance3D

var gun_manager: Node
var player_state: Node
var player_health: Node
var player_movement: Node
var player_camera: Node
var player_input: Node

func initialize_all_systems(p: CharacterBody3D):
	player = p
	
	# Get references to core components
	camera_controller = player.get_node("CameraController")
	camera = player.get_node("CameraController/Camera3D")
	collision_shape = player.get_node("CollisionShape3D")
	mesh_instance = player.get_node("MeshInstance3D")
	
	# Get references to system components
	gun_manager = player.get_node("GunManager")
	player_state = player.get_node("PlayerState")
	player_health = player.get_node("PlayerHealth")
	player_movement = player.get_node("PlayerMovement")
	player_camera = player.get_node("PlayerCamera")
	player_input = player.get_node("PlayerInput")
	
	# Initialize modular components
	player_movement.initialize(player, collision_shape, camera_controller, player_health)
	player_camera.initialize(player, camera_controller, camera, player_movement, player_state)
	player_input.initialize(player, gun_manager, player_camera, player_movement)

# API functions for other systems to access player components
func get_camera() -> Camera3D:
	return player_camera.get_camera()

func get_camera_controller() -> Node3D:
	return player_camera.get_camera_controller()

func get_player_movement() -> Node:
	return player_movement

func get_player_state() -> Node:
	return player_state

func get_player_health() -> Node:
	return player_health

func get_gun_manager() -> Node:
	return gun_manager