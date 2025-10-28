extends Node
class_name GunPhysics

@onready var player: Player = get_parent()
@onready var camera: Camera3D = get_parent().get_node("CameraController/Camera3D")

var held_object: RigidBody3D = null
var object_rotation: Vector3 = Vector3.ZERO
var hold_distance: float = 3.0
var hold_strength: float = 10.0
var interaction_range: float = 50.0
var is_active: bool = false

func activate():
	is_active = true

func deactivate():
	is_active = false
	if held_object:
		release_held_object()

func use_primary():
	grab_object()

func use_secondary():
	release_held_object()

func release_primary():
	if held_object:
		release_held_object()

func release_secondary():
	# Right click doesn't need release handling
	pass

func update_gun(delta: float):
	if is_active and held_object:
		update_held_object(delta)

func get_gun_info() -> Dictionary:
	var info = {
		"name": "PHYSICS GUN",
		"primary": "L-Click: Grab",
		"secondary": "R-Click: Release"
	}
	
	if held_object:
		info["extra"] = "HOLDING: " + held_object.name + " | Scroll: Rotate X | R+Scroll: Rotate Y"
	else:
		info["extra"] = "No object held"
	
	return info

func get_raycast_result() -> Dictionary:
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * interaction_range)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	return space_state.intersect_ray(query)

func grab_object():
	if held_object:
		return
	
	var result = get_raycast_result()
	if result.is_empty():
		return
	
	var collider = result.collider
	if collider is RigidBody3D:
		held_object = collider
		held_object.gravity_scale = 0
		held_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		held_object.freeze = true
		object_rotation = held_object.rotation  # Store current rotation
		print("Grabbed object: ", held_object.name)

func release_held_object():
	if not held_object:
		return
	
	held_object.freeze = false
	held_object.gravity_scale = 1
	held_object.freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	print("Released object: ", held_object.name)
	held_object = null

func handle_scroll(direction: int, is_right_clicking: bool):
	if not held_object:
		return
	
	if is_right_clicking:
		# Right + scroll = rotate around Y axis
		object_rotation.y += direction * 0.2
	else:
		# Scroll alone = rotate around X axis
		object_rotation.x += direction * 0.2
	
	# Apply rotation to held object
	held_object.rotation = object_rotation

func update_held_object(delta: float):
	if not held_object:
		return
	
	var target_position = camera.global_position + (-camera.global_transform.basis.z * hold_distance)
	held_object.global_position = held_object.global_position.lerp(target_position, hold_strength * delta)
	
	# Keep rotation synced
	held_object.rotation = held_object.rotation.lerp(object_rotation, hold_strength * delta)

func get_held_object() -> RigidBody3D:
	return held_object