extends Node
class_name PlayerInput

# References
var player: CharacterBody3D
var gun_manager: Node
var player_camera: Node
var player_movement: Node

# State tracking
var is_right_clicking = false

func initialize(p: CharacterBody3D, gm: Node, pc: Node, pm: Node):
	player = p
	gun_manager = gm
	player_camera = pc
	player_movement = pm

func handle_input(event: InputEvent):
	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		player_camera.handle_mouse_input(event)
	
	# Gun switching
	if event.is_action_pressed("switch_tool"):
		gun_manager.switch_gun()
	elif event.is_action_pressed("tool_1"):
		gun_manager.set_gun(0)  # GUN_ITEM
	elif event.is_action_pressed("tool_2"):
		gun_manager.set_gun(1)  # GUN_PROPS
	elif event.is_action_pressed("tool_3"):
		gun_manager.set_gun(2)  # GUN_PHYSICS
	elif event.is_action_pressed("tool_4"):
		gun_manager.set_gun(3)  # GUN_WEAPON
	
	# Mouse clicks for guns
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				gun_manager.handle_primary_action()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				is_right_clicking = true
				gun_manager.handle_secondary_action()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				gun_manager.handle_scroll_wheel(1, is_right_clicking)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				gun_manager.handle_scroll_wheel(-1, is_right_clicking)
		else:
			if event.button_index == MOUSE_BUTTON_LEFT:
				gun_manager.handle_primary_release()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				is_right_clicking = false
				gun_manager.handle_secondary_release()
	
	# Camera mode toggle (C key)
	if event.is_action_pressed("toggle_camera"):
		player_camera.toggle_camera_mode()
	
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func process_movement_input():
	player_movement.handle_input()