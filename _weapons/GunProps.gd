extends Node
class_name GunProps

@onready var player: Player = get_parent()
@onready var camera: Camera3D = get_parent().get_node("CameraController/Camera3D")

var selected_object: RigidBody3D = null
var interaction_range: float = 50.0
var is_active: bool = false
var properties_menu: Control = null

func activate():
	is_active = true

func deactivate():
	is_active = false
	if selected_object:
		deselect_object()
	hide_properties_menu()

func use_primary():
	select_object_for_editing()

func use_secondary():
	if selected_object:
		show_properties_menu()
	else:
		hide_properties_menu()

func update_gun(_delta: float):
	# Props gun doesn't need continuous updates
	pass

func get_gun_info() -> Dictionary:
	var info = {
		"name": "PROPS GUN",
		"primary": "L-Click: Select",
		"secondary": "R-Click: Properties Menu"
	}
	
	if selected_object:
		info["extra"] = "SELECTED: " + selected_object.name
	else:
		info["extra"] = "No object selected"
	
	return info

func get_raycast_result() -> Dictionary:
	var space_state = player.get_world_3d().direct_space_state
	var from = camera.global_position
	var to = from + (-camera.global_transform.basis.z * interaction_range)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	return space_state.intersect_ray(query)

func select_object_for_editing():
	var result = get_raycast_result()
	if result.is_empty():
		return
	
	var collider = result.collider
	if collider is RigidBody3D:
		if selected_object:
			deselect_object()
		
		selected_object = collider
		# Add visual indicator (outline or highlight)
		add_selection_outline()
		print("Selected object for property editing: ", selected_object.name)

func deselect_object():
	if selected_object:
		remove_selection_outline()
		print("Deselected object: ", selected_object.name)
		selected_object = null

func add_selection_outline():
	# Simple implementation - could be enhanced with proper outline shader
	if selected_object and selected_object.get_child_count() > 0:
		var child_mesh = selected_object.get_child(0)
		if child_mesh is MeshInstance3D:
			# Create a simple colored material to indicate selection
			var outline_material = StandardMaterial3D.new()
			outline_material.albedo_color = Color.YELLOW
			outline_material.flags_transparent = true
			outline_material.albedo_color.a = 0.7
			child_mesh.material_overlay = outline_material

func remove_selection_outline():
	if selected_object and selected_object.get_child_count() > 0:
		var child_mesh = selected_object.get_child(0)
		if child_mesh is MeshInstance3D:
			child_mesh.material_overlay = null

func modify_object_properties(property: String, value: float):
	if not selected_object:
		return
	
	match property:
		"mass":
			selected_object.mass = value
		"gravity_scale":
			selected_object.gravity_scale = value
		"friction":
			if selected_object.get_child_count() > 1:
				var collision = selected_object.get_child(1)
				if collision is CollisionShape3D and collision.shape:
					# Friction is handled by physics material
					var physics_material = PhysicsMaterial.new()
					physics_material.friction = value
					collision.shape.set_meta("physics_material", physics_material)
	
	print("Modified ", property, " to ", value, " for ", selected_object.name)

func get_selected_object() -> RigidBody3D:
	return selected_object

func show_properties_menu():
	if not selected_object:
		return
	
	# Create properties menu if it doesn't exist
	if not properties_menu:
		create_properties_menu()
	
	# Update values and show menu
	update_properties_menu_values()
	properties_menu.visible = true
	
	# Capture mouse for the UI
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	print("Showing properties menu for: ", selected_object.name)

func hide_properties_menu():
	if properties_menu:
		properties_menu.visible = false
	
	# Restore mouse capture
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func deselect_and_close():
	deselect_object()
	hide_properties_menu()

func create_properties_menu():
	# Create a panel for the properties menu
	properties_menu = Panel.new()
	properties_menu.size = Vector2(300, 400)
	properties_menu.position = Vector2(50, 50)
	properties_menu.visible = false
	
	# Add to main scene
	var main_scene = player.get_parent()
	main_scene.add_child(properties_menu)
	
	# Create VBox container for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(280, 380)
	properties_menu.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Object Properties"
	title_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title_label)
	
	# Mass control
	create_property_control(vbox, "Mass", "mass", 0.1, 100.0, 1.0)
	
	# Gravity scale control
	create_property_control(vbox, "Gravity Scale", "gravity_scale", 0.0, 5.0, 1.0)
	
	# Friction control  
	create_property_control(vbox, "Friction", "friction", 0.0, 2.0, 1.0)
	
	# Bounce control
	create_property_control(vbox, "Bounce", "bounce", 0.0, 1.0, 0.0)
	
	# Linear damp control
	create_property_control(vbox, "Linear Damp", "linear_damp", 0.0, 10.0, 0.0)
	
	# Angular damp control
	create_property_control(vbox, "Angular Damp", "angular_damp", 0.0, 10.0, 0.0)
	
	# Close button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(hide_properties_menu)
	vbox.add_child(close_button)
	
	# Deselect button
	var deselect_button = Button.new()
	deselect_button.text = "Deselect Object"
	deselect_button.pressed.connect(deselect_and_close)
	vbox.add_child(deselect_button)

func create_property_control(parent: VBoxContainer, label_text: String, property_name: String, min_val: float, max_val: float, default_val: float):
	# Property label
	var label = Label.new()
	label.text = label_text + ":"
	parent.add_child(label)
	
	# Horizontal container for slider and value label
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	# Slider
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.step = 0.1
	slider.value = default_val
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.set_meta("property_name", property_name)
	slider.value_changed.connect(_on_property_changed.bind(slider))
	hbox.add_child(slider)
	
	# Value label
	var value_label = Label.new()
	value_label.text = str(default_val)
	value_label.custom_minimum_size.x = 50
	value_label.set_meta("property_name", property_name)
	hbox.add_child(value_label)
	
	# Store references for easy access
	slider.set_meta("value_label", value_label)

func update_properties_menu_values():
	if not properties_menu or not selected_object:
		return
	
	# Update slider values based on current object properties
	var sliders = find_all_sliders(properties_menu)
	for slider in sliders:
		var property_name = slider.get_meta("property_name", "")
		var value_label = slider.get_meta("value_label")
		
		var current_value = get_object_property_value(property_name)
		slider.value = current_value
		if value_label:
			value_label.text = "%.2f" % current_value

func find_all_sliders(node: Node) -> Array[HSlider]:
	var sliders: Array[HSlider] = []
	
	if node is HSlider:
		sliders.append(node)
	
	for child in node.get_children():
		sliders.append_array(find_all_sliders(child))
	
	return sliders

func get_object_property_value(property_name: String) -> float:
	if not selected_object:
		return 0.0
	
	match property_name:
		"mass":
			return selected_object.mass
		"gravity_scale":
			return selected_object.gravity_scale
		"linear_damp":
			return selected_object.linear_damp
		"angular_damp":
			return selected_object.angular_damp
		"friction", "bounce":
			# These would need physics material access
			return 1.0 if property_name == "friction" else 0.0
		_:
			return 0.0

func _on_property_changed(value: float, calling_slider: HSlider):
	var property_name = calling_slider.get_meta("property_name", "")
	var value_label = calling_slider.get_meta("value_label")
	
	# Update the value label
	if value_label:
		value_label.text = "%.2f" % value
	
	# Apply the property change to the selected object
	apply_property_change(property_name, value)

func apply_property_change(property_name: String, value: float):
	if not selected_object:
		return
	
	match property_name:
		"mass":
			selected_object.mass = value
		"gravity_scale":
			selected_object.gravity_scale = value
		"linear_damp":
			selected_object.linear_damp = value
		"angular_damp":
			selected_object.angular_damp = value
		"friction":
			# Apply friction via physics material
			apply_physics_material_property("friction", value)
		"bounce":
			# Apply bounce via physics material
			apply_physics_material_property("bounce", value)
	
	print("Applied ", property_name, ": ", value, " to ", selected_object.name)

func apply_physics_material_property(property_name: String, value: float):
	if not selected_object:
		return
	
	# Find the collision shape
	for child in selected_object.get_children():
		if child is CollisionShape3D:
			var collision = child as CollisionShape3D
			
			# Get or create physics material on the CollisionShape3D node
			var physics_material = collision.physics_material
			if not physics_material:
				physics_material = PhysicsMaterial.new()
				collision.physics_material = physics_material
			
			# Apply the property
			match property_name:
				"friction":
					physics_material.friction = value
				"bounce":
					physics_material.bounce = value
			
			print("Applied physics material property: ", property_name, " = ", value)
			break