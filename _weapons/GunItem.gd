extends Node
class_name GunItem

@onready var player: Player = get_parent()
@onready var camera: Camera3D = get_parent().get_node("CameraController/Camera3D")

var preview_object: MeshInstance3D = null
var preview_material: StandardMaterial3D = null
var interaction_range: float = 50.0
var is_active: bool = false

func activate():
	is_active = true
	setup_preview_material()
	print("Item Gun: Activated")

func deactivate():
	is_active = false
	hide_preview()
	print("Item Gun: Deactivated")

func use_primary():
	spawn_item()

func use_secondary():
	remove_item()

func update_gun(_delta: float):
	if is_active:
		update_preview()
	# Debug: Uncomment to see if update_gun is being called
	# print("Item Gun: update_gun called, is_active: ", is_active)

func get_gun_info() -> Dictionary:
	return {
		"name": "ITEM GUN",
		"primary": "L-Click: Spawn",
		"secondary": "R-Click: Remove", 
		"extra": "Shows wireframe preview"
	}

func get_raycast_result() -> Dictionary:
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * interaction_range)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	return space_state.intersect_ray(query)

func spawn_item():
	var result = get_raycast_result()
	if result.is_empty():
		return
	
	var spawn_position = result.position + result.normal * 0.5
	
	# Create a CSG box as an item
	var item = create_csg_item()
	player.get_parent().add_child(item)
	item.global_position = spawn_position
	
	print("Spawned item at: ", spawn_position)

func remove_item():
	var result = get_raycast_result()
	if result.is_empty():
		return
	
	var collider = result.collider
	if collider and collider.has_method("queue_free"):
		# Check if it's a spawned item (has our custom group or is a CSG shape)
		if collider.is_in_group("spawned_items") or collider is CSGShape3D:
			collider.queue_free()
			print("Removed item")

func create_csg_item() -> RigidBody3D:
	# Create RigidBody3D with CSG shape
	var rigid_body = RigidBody3D.new()
	rigid_body.add_to_group("spawned_items")
	
	# Set physics properties for better interaction
	rigid_body.mass = randf_range(2.0, 8.0)  # Random mass for variety
	rigid_body.gravity_scale = 1.0
	rigid_body.linear_damp = randf_range(1.0, 3.0)  # Random damping for variety
	rigid_body.angular_damp = randf_range(3.0, 6.0)
	
	# Add physics material for realistic interactions
	var physics_material = PhysicsMaterial.new()
	physics_material.friction = randf_range(0.4, 0.9)
	physics_material.bounce = randf_range(0.1, 0.4)
	rigid_body.physics_material_override = physics_material
	
	# Create CSG Box
	var csg_box = CSGBox3D.new()
	csg_box.size = Vector3(1, 1, 1)
	
	# Create red material for spawned items
	var red_material = StandardMaterial3D.new()
	red_material.albedo_color = Color(1, 0, 0, 1)  # Bright red
	red_material.roughness = 0.4
	red_material.metallic = 0.0
	csg_box.material_override = red_material
	
	rigid_body.add_child(csg_box)
	
	# Add collision shape
	var item_collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1, 1, 1)
	item_collision.shape = box_shape
	
	rigid_body.add_child(item_collision)
	
	return rigid_body

func setup_preview_material():
	if not preview_material:
		preview_material = StandardMaterial3D.new()
		preview_material.flags_transparent = true
		preview_material.albedo_color = Color(1, 0, 0, 0.9)  # Bright red wireframe
		preview_material.flags_use_point_size = true
		preview_material.no_depth_test = true  # Always visible through walls
		preview_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		preview_material.flags_do_not_receive_shadows = true
		preview_material.flags_disable_ambient_light = true
		# Note: wireframe mode doesn't exist in Godot 4, using solid with transparency
		preview_material.emission_enabled = true
		preview_material.emission = Color(1, 0.3, 0.3, 1)  # Red glow
		preview_material.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED

func update_preview():
	var result = get_raycast_result()
	if result.is_empty():
		hide_preview()
		print("Item Gun: No raycast hit, hiding preview")
		return
	
	print("Item Gun: Raycast hit at ", result.position)
	show_preview(result.position + result.normal * 0.5)

func show_preview(spawn_position: Vector3):
	print("Item Gun: Showing preview at ", spawn_position)
	if not preview_object:
		print("Item Gun: Creating new preview object")
		preview_object = MeshInstance3D.new()
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(1, 1, 1)
		preview_object.mesh = box_mesh
		setup_preview_material()
		preview_object.material_override = preview_material
		preview_object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		preview_object.visibility_range_begin = 0.0
		preview_object.visibility_range_end = 1000.0
		player.get_parent().add_child(preview_object)
		print("Item Gun: Preview object created and added to scene")
	
	preview_object.global_position = spawn_position
	preview_object.visible = true
	print("Item Gun: Preview object visible: ", preview_object.visible)

func hide_preview():
	if preview_object:
		preview_object.visible = false
