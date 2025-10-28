extends Node
class_name PlayerHealth

signal health_changed(new_health: int, max_health: int)
signal player_died()
signal player_respawned()

@onready var player: Player = get_parent()
@onready var player_state = get_parent().get_node("PlayerState")

# Health system
const MAX_HEALTH: int = 100
var current_health: int = MAX_HEALTH

# Respawn system
var spawn_position: Vector3 = Vector3(0, 8, 0)  # Default spawn height
var respawn_delay: float = 2.0
var is_dead: bool = false

# Damage immunity (brief period after taking damage)
var damage_immunity_duration: float = 1.0
var damage_immunity_timer: float = 0.0

func _ready():
	current_health = MAX_HEALTH
	# Store initial spawn position
	spawn_position = player.global_position
	print("PlayerHealth initialized - Health: ", current_health)

func _physics_process(delta):
	# Update damage immunity timer
	if damage_immunity_timer > 0:
		damage_immunity_timer -= delta

func take_damage(amount: int, damage_source: String = "Unknown"):
	# Check if player can take damage
	if not can_take_damage():
		print("Damage blocked: ", damage_source, " (", amount, " damage)")
		return false
	
	# Apply damage
	current_health = max(0, current_health - amount)
	damage_immunity_timer = damage_immunity_duration
	
	print("Took ", amount, " damage from ", damage_source, " - Health: ", current_health, "/", MAX_HEALTH)
	health_changed.emit(current_health, MAX_HEALTH)
	
	# Check for death
	if current_health <= 0 and not is_dead:
		die()
	
	return true

func heal(amount: int, heal_source: String = "Unknown"):
	if is_dead:
		return false
	
	var old_health = current_health
	current_health = min(MAX_HEALTH, current_health + amount)
	
	if current_health != old_health:
		print("Healed ", current_health - old_health, " health from ", heal_source, " - Health: ", current_health, "/", MAX_HEALTH)
		health_changed.emit(current_health, MAX_HEALTH)
	
	return true

func can_take_damage() -> bool:
	# Can't take damage if invincible, dead, or in damage immunity period
	if is_dead:
		return false
	if player_state and player_state.is_invincible():
		return false
	if damage_immunity_timer > 0:
		return false
	
	return true

func die():
	if is_dead:
		return
	
	is_dead = true
	current_health = 0
	print("Player died!")
	player_died.emit()
	
	# Disable player controls temporarily
	player.set_physics_process(false)
	
	# Start respawn timer
	await get_tree().create_timer(respawn_delay).timeout
	respawn()

func respawn():
	if not is_dead:
		return
	
	is_dead = false
	current_health = MAX_HEALTH
	damage_immunity_timer = damage_immunity_duration * 2  # Extra immunity on respawn
	
	# Reset player position
	player.global_position = spawn_position
	player.velocity = Vector3.ZERO
	
	# Re-enable player controls
	player.set_physics_process(true)
	
	print("Player respawned at ", spawn_position, " - Health: ", current_health)
	health_changed.emit(current_health, MAX_HEALTH)
	player_respawned.emit()

func teleport_to_spawn():
	# Teleport player back to spawn without death requirement
	print("Teleporting player to spawn at ", spawn_position)
	player.global_position = spawn_position
	player.velocity = Vector3.ZERO
	damage_immunity_timer = damage_immunity_duration  # Brief immunity after teleport
	player_respawned.emit()

func set_spawn_point(position: Vector3):
	spawn_position = position
	print("Spawn point set to: ", spawn_position)

func get_health_percentage() -> float:
	return float(current_health) / float(MAX_HEALTH) * 100.0

func get_health_info() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": MAX_HEALTH,
		"health_percentage": get_health_percentage(),
		"is_dead": is_dead,
		"has_immunity": damage_immunity_timer > 0,
		"immunity_time": damage_immunity_timer,
		"health_text": str(current_health) + "/" + str(MAX_HEALTH),
		"health_bar_value": get_health_percentage()
	}

func is_player_dead() -> bool:
	return is_dead

func reset_health():
	current_health = MAX_HEALTH
	is_dead = false
	damage_immunity_timer = 0.0
	health_changed.emit(current_health, MAX_HEALTH)
	print("Health reset to full")

# Debug functions
func set_health(health: int):
	if health < 0:
		health = 0
	elif health > MAX_HEALTH:
		health = MAX_HEALTH
	
	current_health = health
	health_changed.emit(current_health, MAX_HEALTH)
	
	if current_health <= 0 and not is_dead:
		die()

func kill_player():
	take_damage(current_health, "Debug Kill")

# Environmental damage triggers
func apply_fall_damage(fall_velocity: float):
	# Apply fall damage based on fall speed
	var damage_threshold = 15.0  # Minimum velocity to take damage
	if fall_velocity > damage_threshold:
		var damage = int((fall_velocity - damage_threshold) * 2)
		take_damage(damage, "Fall Damage")

func apply_environmental_damage(damage: int, source: String):
	take_damage(damage, source)