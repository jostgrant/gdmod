extends Control

@onready var player = get_node("../Player")
@onready var status_label = $VBoxContainer/StatusLabel
@onready var controls_label = $VBoxContainer/ControlsLabel

func _ready():
	controls_label.text = """CONTROLS:
WASD - Move (Walk into objects to push them!)
Mouse - Look around
Space - Jump
Shift - Run (Run into objects for stronger push!)
Ctrl - Crouch
C - Toggle First/Third Person Camera (Third person default)
V - Toggle Noclip (auto third person)
I - Toggle Invincibility
Q - Switch Gun | 1/2/3/4 - Quick Select
1 - Item Gun (spawn/remove + preview)
2 - Props Gun (select objects + properties menu)
3 - Physics Gun (grab/rotate objects)
4 - Weapon Gun (launch balls)
Left Click - Primary Action
Right Click - Secondary Action (Properties Menu for Props Gun)
Scroll - Rotate (Physics Gun)
R+Scroll - Rotate Other Axis
Esc - Toggle mouse capture

PHYSICS: Walk/run into boxes to push them around!
Different colored boxes have different masses."""

func _process(_delta):
	if player:
		var status_text = ""
		
		# Health information
		if player.player_api.player_health:
			var health_info = player.player_api.player_health.get_health_info()
			status_text += "HEALTH: " + health_info.get("health_text", "100/100") + "\n"
			if health_info.get("has_immunity", false):
				status_text += "DAMAGE IMMUNITY\n"
		
		# State information
		if player.player_api.player_state:
			var state_info = player.player_api.player_state.get_state_info()
			status_text += state_info.get("noclip_text", "NOCLIP: OFF") + "\n"
			status_text += state_info.get("invincibility_text", "INVINCIBLE: OFF") + "\n"
		
		# Movement information
		status_text += "Speed: %.1f\n" % Vector2(player.velocity.x, player.velocity.z).length()
		status_text += "Height: %.1f\n" % player.global_position.y
		
		if player.player_api.player_movement.is_crouching:
			status_text += "CROUCHING\n"
		elif player.player_api.player_movement.is_running:
			status_text += "RUNNING\n"
		else:
			status_text += "WALKING\n"
		
		if player.is_on_floor():
			status_text += "ON GROUND\n"
		else:
			status_text += "IN AIR\n"
		
		# Camera information
		if player.player_api.player_camera:
			var camera_mode = player.player_api.player_camera.get_camera_mode()
			if camera_mode == 0:  # FIRST_PERSON
				status_text += "CAMERA: FIRST PERSON\n"
			else:  # THIRD_PERSON
				status_text += "CAMERA: THIRD PERSON\n"
		
		# Gun information
		if player.player_api.gun_manager:
			var gun_info = player.player_api.gun_manager.get_current_gun_info()
			status_text += "GUN: " + gun_info.get("name", "UNKNOWN") + "\n"
			status_text += gun_info.get("primary", "") + " | " + gun_info.get("secondary", "") + "\n"
			status_text += gun_info.get("extra", "")
		
		status_label.text = status_text