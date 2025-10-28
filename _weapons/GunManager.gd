extends Node
class_name GunManager

signal gun_changed(new_gun: Gun)

enum Gun { GUN_ITEM, GUN_PROPS, GUN_PHYSICS, GUN_WEAPON }

@export var current_gun: Gun = Gun.GUN_ITEM

@onready var gun_item: GunItem
@onready var gun_props: GunProps
@onready var gun_physics: GunPhysics
@onready var gun_weapon: GunWeapon

func _ready():
	# Get references to gun components
	gun_item = get_node("../GunItem")
	gun_props = get_node("../GunProps")
	gun_physics = get_node("../GunPhysics")
	gun_weapon = get_node("../GunWeapon")
	
	# Activate initial gun
	_activate_current_gun()

func switch_gun():
	match current_gun:
		Gun.GUN_ITEM:
			set_gun(Gun.GUN_PROPS)
		Gun.GUN_PROPS:
			set_gun(Gun.GUN_PHYSICS)
		Gun.GUN_PHYSICS:
			set_gun(Gun.GUN_WEAPON)
		Gun.GUN_WEAPON:
			set_gun(Gun.GUN_ITEM)

func set_gun(new_gun: Gun):
	if new_gun == current_gun:
		return
	
	# Deactivate current gun
	_deactivate_current_gun()
	
	# Switch to new gun
	current_gun = new_gun
	
	# Activate new gun
	_activate_current_gun()
	
	# Emit signal
	gun_changed.emit(current_gun)
	
	# Print feedback
	match current_gun:
		Gun.GUN_ITEM:
			print("Switched to Item Gun")
		Gun.GUN_PROPS:
			print("Switched to Props Gun")
		Gun.GUN_PHYSICS:
			print("Switched to Physics Gun")
		Gun.GUN_WEAPON:
			print("Switched to Weapon Gun")

func _activate_current_gun():
	match current_gun:
		Gun.GUN_ITEM:
			gun_item.activate()
		Gun.GUN_PROPS:
			gun_props.activate()
		Gun.GUN_PHYSICS:
			gun_physics.activate()
		Gun.GUN_WEAPON:
			gun_weapon.activate()

func _deactivate_current_gun():
	match current_gun:
		Gun.GUN_ITEM:
			gun_item.deactivate()
		Gun.GUN_PROPS:
			gun_props.deactivate()
		Gun.GUN_PHYSICS:
			gun_physics.deactivate()
		Gun.GUN_WEAPON:
			gun_weapon.deactivate()

func handle_primary_action():
	match current_gun:
		Gun.GUN_ITEM:
			gun_item.use_primary()
		Gun.GUN_PROPS:
			gun_props.use_primary()
		Gun.GUN_PHYSICS:
			gun_physics.use_primary()
		Gun.GUN_WEAPON:
			gun_weapon.use_primary()

func handle_secondary_action():
	match current_gun:
		Gun.GUN_ITEM:
			gun_item.use_secondary()
		Gun.GUN_PROPS:
			gun_props.use_secondary()
		Gun.GUN_PHYSICS:
			gun_physics.use_secondary()
		Gun.GUN_WEAPON:
			gun_weapon.use_secondary()

func handle_primary_release():
	match current_gun:
		Gun.GUN_PHYSICS:
			gun_physics.release_primary()
		Gun.GUN_WEAPON:
			gun_weapon.release_primary()

func handle_secondary_release():
	match current_gun:
		Gun.GUN_PHYSICS:
			gun_physics.release_secondary()
		Gun.GUN_WEAPON:
			gun_weapon.release_secondary()

func handle_scroll_wheel(direction: int, is_right_clicking: bool):
	match current_gun:
		Gun.GUN_PHYSICS:
			gun_physics.handle_scroll(direction, is_right_clicking)
		Gun.GUN_WEAPON:
			gun_weapon.handle_scroll(direction, is_right_clicking)

func update_guns(delta: float):
	match current_gun:
		Gun.GUN_ITEM:
			gun_item.update_gun(delta)
		Gun.GUN_PROPS:
			gun_props.update_gun(delta)
		Gun.GUN_PHYSICS:
			gun_physics.update_gun(delta)
		Gun.GUN_WEAPON:
			gun_weapon.update_gun(delta)

func get_current_gun_info() -> Dictionary:
	match current_gun:
		Gun.GUN_ITEM:
			return gun_item.get_gun_info()
		Gun.GUN_PROPS:
			return gun_props.get_gun_info()
		Gun.GUN_PHYSICS:
			return gun_physics.get_gun_info()
		Gun.GUN_WEAPON:
			return gun_weapon.get_gun_info()
	
	return {}