extends Node
class_name GunWeapon

@onready var player: Player = get_parent()
@onready var camera: Camera3D = get_parent().get_node("CameraController/Camera3D")

var projectile_speed: float = 20.0
var projectile_force: float = 500.0
var max_projectiles: int = 10
var active_projectiles: Array[RigidBody3D] = []
var is_active: bool = false

# Projectile settings
var projectile_lifetime: float = 5.0

func activate():
	is_active = true

func deactivate():
	is_active = false
	# Clean up any remaining projectiles
	cleanup_projectiles()

func use_primary():
	launch_projectile()

func use_secondary():
	# Secondary could be different projectile type or charged shot
	launch_charged_projectile()

func release_primary():
	# Weapon gun doesn't need release handling for primary
	pass

func release_secondary():
	# Weapon gun doesn't need release handling for secondary
	pass

func handle_scroll(_direction: int, _is_right_clicking: bool):
	# Could be used for weapon adjustments later
	pass

func update_gun(delta: float):
	if is_active:
		update_projectiles(delta)

func get_gun_info() -> Dictionary:
	return {
		"name": "WEAPON GUN",
		"primary": "L-Click: Launch Ball",
		"secondary": "R-Click: Charged Ball",
		"extra": "Balls affect spawned items only"
	}

func launch_projectile():
	# Clean up old projectiles if we have too many
	if active_projectiles.size() >= max_projectiles:
		cleanup_oldest_projectile()
	
	var projectile = create_projectile()
	player.get_parent().add_child(projectile)
	
	# Position at camera
	projectile.global_position = camera.global_position + (-camera.global_transform.basis.z * 0.5)
	
	# Launch in camera direction
	var launch_direction = -camera.global_transform.basis.z
	projectile.linear_velocity = launch_direction * projectile_speed
	
	active_projectiles.append(projectile)
	print("Launched projectile")

func launch_charged_projectile():
	# Similar to normal but with more force and speed
	if active_projectiles.size() >= max_projectiles:
		cleanup_oldest_projectile()
	
	var projectile = create_projectile(true)
	player.get_parent().add_child(projectile)
	
	# Position at camera
	projectile.global_position = camera.global_position + (-camera.global_transform.basis.z * 0.5)
	
	# Launch in camera direction with more power
	var launch_direction = -camera.global_transform.basis.z
	projectile.linear_velocity = launch_direction * (projectile_speed * 1.5)
	
	active_projectiles.append(projectile)
	print("Launched charged projectile")

func create_projectile(charged: bool = false) -> RigidBody3D:
	var projectile = RigidBody3D.new()
	projectile.add_to_group("weapon_projectiles")
	
	# Create sphere mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	var radius = 0.1 if not charged else 0.15
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	mesh_instance.mesh = sphere_mesh
	
	# Create material
	var material = StandardMaterial3D.new()
	if charged:
		material.albedo_color = Color.RED
		material.emission = Color.RED * 0.5
	else:
		material.albedo_color = Color.CYAN
		material.emission = Color.CYAN * 0.3
	mesh_instance.material_override = material
	
	projectile.add_child(mesh_instance)
	
	# Add collision
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	collision_shape.shape = sphere_shape
	projectile.add_child(collision_shape)
	
	# Set projectile properties
	projectile.mass = 0.1
	projectile.gravity_scale = 0.2  # Light gravity so balls arc slightly
	
	# Connect collision signal
	projectile.body_entered.connect(_on_projectile_collision.bind(projectile, charged))
	
	# Set custom properties
	projectile.set_meta("creation_time", Time.get_time_dict_from_system())
	projectile.set_meta("force", projectile_force * (2.0 if charged else 1.0))
	
	return projectile

func _on_projectile_collision(projectile: RigidBody3D, charged: bool, body: Node):
	if body == player:
		return  # Don't collide with player
	
	# Check if it's a spawned item
	if body.is_in_group("spawned_items"):
		apply_projectile_effect(projectile, body, charged)
		cleanup_projectile(projectile)
	elif body is StaticBody3D:
		# Hit ground or wall - just remove projectile
		cleanup_projectile(projectile)

func apply_projectile_effect(projectile: RigidBody3D, target: RigidBody3D, _charged: bool):
	var force = projectile.get_meta("force", projectile_force)
	var impact_direction = (target.global_position - projectile.global_position).normalized()
	
	# Apply impulse to the target
	target.apply_central_impulse(impact_direction * force)
	
	# Visual effect (could be enhanced)
	print("Projectile hit ", target.name, " with force ", force)
	
	# Could add particle effects, sound, etc. here

func update_projectiles(_delta: float):
	# Remove projectiles that are too old
	var current_time = Time.get_time_dict_from_system()
	var projectiles_to_remove = []
	
	for projectile in active_projectiles:
		if projectile and is_instance_valid(projectile):
			var creation_time = projectile.get_meta("creation_time", current_time)
			var elapsed = (current_time.hour * 3600 + current_time.minute * 60 + current_time.second) - \
						  (creation_time.hour * 3600 + creation_time.minute * 60 + creation_time.second)
			
			if elapsed > projectile_lifetime:
				projectiles_to_remove.append(projectile)
		else:
			projectiles_to_remove.append(projectile)
	
	for projectile in projectiles_to_remove:
		cleanup_projectile(projectile)

func cleanup_projectile(projectile: RigidBody3D):
	if projectile and is_instance_valid(projectile):
		active_projectiles.erase(projectile)
		projectile.queue_free()

func cleanup_oldest_projectile():
	if active_projectiles.size() > 0:
		cleanup_projectile(active_projectiles[0])

func cleanup_projectiles():
	for projectile in active_projectiles:
		if projectile and is_instance_valid(projectile):
			projectile.queue_free()
	active_projectiles.clear()