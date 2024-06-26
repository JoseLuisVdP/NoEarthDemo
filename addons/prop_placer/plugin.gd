@tool
extends EditorPlugin

const plugin_name := "Prop Placer"

const preview_size: int = 128

const GuiHandler := preload("res://addons/prop_placer/gui_handler.gd")
const Collection := preload("res://addons/prop_placer/collection.gd")
var gui := preload("res://addons/prop_placer/gui.tscn")

var gui_instance: GuiHandler

var root_node: Node
var scene_root: Node

var undo_redo: EditorUndoRedoManager

var grid_enabled := true
var grid_plane := Plane(Vector3.UP, 0.0)
var grid_step := 1.0
var grid_offset := 0.0
var align_to_surface := false
var icon_size : int = 4

# String (uid), Collection
var collections: Dictionary

var brush: Node3D
var selected_asset: Dictionary

var rotation := Vector3.ZERO

func _enter_tree() -> void:
	scene_root = EditorInterface.get_edited_scene_root()

	scene_changed.connect(_on_scene_changed)

	gui_instance = gui.instantiate() as GuiHandler
	gui_instance.prop_placer_instance = self
	
	gui_instance.version_label.text = plugin_name + " v" + get_plugin_version()
	add_control_to_bottom_panel(gui_instance, plugin_name)

	undo_redo = get_undo_redo()

func _exit_tree() -> void:
	remove_control_from_bottom_panel(gui_instance)
	gui_instance.free()
	if brush:
		brush.free()

func _enable_plugin() -> void:
	set_root_node(null)

func _on_scene_changed(_scene_root: Node) -> void:
	set_root_node(null)
	if is_instance_valid(self.scene_root):
		if is_instance_valid(brush):
			self.scene_root.remove_child(brush)
	
	self.scene_root = _scene_root

	if is_instance_valid(self.scene_root):
		if is_instance_valid(brush):
			self.scene_root.add_child(brush)

func _handles(_object: Object) -> bool:
	return true

func set_root_node(node: Node) -> void:
	root_node = node

	if node == null:
		gui_instance.root_node_button.text = "Select"
		gui_instance.root_node_button.icon = EditorInterface.get_editor_theme().get_icon("StatusWarning", "EditorIcons")

		if brush:
			brush.hide()
	else:
		gui_instance.root_node_button.text = root_node.name
		gui_instance.root_node_button.icon = EditorInterface.get_editor_theme().get_icon(node.get_class(), "EditorIcons")
		if brush:
			brush.show()

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if not selected_asset or not root_node:
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	var result := raycast(viewport_camera)

	if result:
		brush.rotation = rotation

		if grid_enabled:
			result.position.y = grid_plane.d
			result.position = result.position.snapped(Vector3(grid_step, 0.0, grid_step))
			result.position += Vector3(grid_offset, 0.0, grid_offset)
		elif align_to_surface:
			brush.transform = align_with_normal(brush.transform, result.normal)

		brush.position = result.position

	if event is InputEventMouseButton:
		if event.is_pressed():
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if result:
						instantiate_asset(result.position, selected_asset)
						return EditorPlugin.AFTER_GUI_INPUT_STOP
				
				MOUSE_BUTTON_RIGHT:
					rotation.y = wrapf(rotation.y + (PI/4.0), 0.0, TAU)
					return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS

# taken from https://github.com/godotengine/godot/issues/85903#issuecomment-1846245217
func align_with_normal(xform: Transform3D, n2: Vector3) -> Transform3D:
	var n1 := xform.basis.y.normalized()
	var cosa := n1.dot(n2)
	if cosa >= 0.99:
		return xform
	var alpha := acos(cosa)
	var axis := n1.cross(n2).normalized()
	if axis == Vector3.ZERO:
		axis = Vector3.FORWARD # normals are in opposite directions
	return xform.rotated(axis, alpha)

func raycast(camera: Camera3D) -> Dictionary:
	var result := Dictionary()
	if grid_enabled:
		var mousepos := EditorInterface.get_editor_viewport_3d().get_mouse_position()
		var pos: Variant = grid_plane.intersects_ray(camera.project_ray_origin(mousepos), camera.project_ray_normal(mousepos) * 1000.0)
		if pos:
			result.position = pos
	else:
		var space_state := camera.get_world_3d().direct_space_state
		var mousepos := EditorInterface.get_editor_viewport_3d().get_mouse_position()

		var origin := camera.project_ray_origin(mousepos)
		var end := origin + camera.project_ray_normal(mousepos) * 1000.0
		var query := PhysicsRayQueryParameters3D.create(origin, end)

		result = space_state.intersect_ray(query)

	return result

func set_grid_enabled(enabled: bool) -> void:
	grid_enabled = enabled

func set_grid_level(value: float) -> void:
	grid_plane.d = value

func set_grid_step(value: float) -> void:
	grid_step = value

func set_grid_offset(value: float) -> void:
	grid_offset = value

func _get_window_layout(configuration: ConfigFile) -> void:
	var collection_ids: Array[String] = []
	for uid: String in collections.keys():
		collection_ids.append(uid)
	
	configuration.set_value(plugin_name, "collections", collection_ids)

	configuration.set_value(plugin_name, "grid_enabled", grid_enabled)
	configuration.set_value(plugin_name, "grid_level", grid_plane.d)
	configuration.set_value(plugin_name, "grid_step", grid_step)
	configuration.set_value(plugin_name, "grid_offset", grid_offset)
	configuration.set_value(plugin_name, "align_to_surface", align_to_surface)
	configuration.set_value(plugin_name, "icon_size", icon_size)

func _set_window_layout(configuration: ConfigFile) -> void:
	var collection_ids: Array[String] = configuration.get_value(plugin_name, "collections", [])

	for uid: String in collection_ids:
		if ResourceUID.has_id(ResourceUID.text_to_id(uid)):
			var res := ResourceLoader.load(uid) as Collection
			if res:
				collections[uid] = res

				gui_instance.spawn_collection_tab(uid, res)

	grid_enabled = configuration.get_value(plugin_name, "grid_enabled", false)
	gui_instance.grid_button.set_pressed_no_signal(grid_enabled)

	grid_plane.d = configuration.get_value(plugin_name, "grid_level", 0.0)
	gui_instance.grid_level.text = str(grid_plane.d)

	grid_step = configuration.get_value(plugin_name, "grid_step", 1.0)
	gui_instance.grid_step.text = str(grid_step)

	grid_offset = configuration.get_value(plugin_name, "grid_offset", 0.0)
	gui_instance.grid_offset.text = str(grid_offset)

	align_to_surface = configuration.get_value(plugin_name, "align_to_surface", false)
	gui_instance.align_to_surface_button.set_pressed_no_signal(align_to_surface)

	icon_size = configuration.get_value(plugin_name, "icon_size", 4)
	gui_instance.icon_size_slider.set_value_no_signal(float(icon_size))
	gui_instance.set_collection_icon_size()

func generate_preview(node: Node) -> Texture2D:
	gui_instance.preview_viewport.add_child(node)
	gui_instance.preview_viewport.size = Vector2i(preview_size, preview_size)

	var aabb := get_aabb(node)

	if is_zero_approx(aabb.size.length()):
		return

	var max_size := max(aabb.size.x, aabb.size.y, aabb.size.z) as float

	gui_instance.preview_camera.size = max_size * 2.0
	gui_instance.preview_camera.look_at_from_position(Vector3(max_size, max_size, max_size), aabb.get_center())

	await RenderingServer.frame_post_draw
	var viewport_image := gui_instance.preview_viewport.get_texture().get_image()
	var preview := PortableCompressedTexture2D.new()
	preview.create_from_image(viewport_image, PortableCompressedTexture2D.COMPRESSION_MODE_LOSSY)
	
	gui_instance.preview_viewport.remove_child(node)
	node.queue_free()

	return preview

func get_aabb(node: Node) -> AABB:
	var aabb := AABB()

	var children: Array[Node] = []
	children.append(node)

	while not children.is_empty():
		var child := children.pop_back() as Node

		if child is VisualInstance3D:
			var child_aabb := child.get_aabb().abs() as AABB
			var transformed_aabb := AABB(child_aabb.position + child.global_position, child_aabb.size)
			aabb = aabb.merge(transformed_aabb)
		
		children.append_array(child.get_children())

	return aabb

func _save_external_data() -> void:
	for collection: Collection in collections.values():
		ResourceSaver.save(collection)

func change_brush(asset: Dictionary) -> void:
	if asset.is_empty():
		return
	selected_asset = asset

	if brush:
		brush.free()
	var packedscene := ResourceLoader.load(asset.uid) as PackedScene

	if packedscene:
		var new_brush := packedscene.instantiate()
		brush = new_brush

		if scene_root:
			scene_root.add_child(brush)

		if not root_node:
			brush.hide()

func instantiate_asset(position: Vector3, asset: Dictionary) -> void:
	var packedscene := ResourceLoader.load(asset.uid) as PackedScene

	if packedscene:
		var instance := packedscene.instantiate() as Node3D

		undo_redo.create_action("Instantiate Asset", UndoRedo.MERGE_DISABLE, scene_root)
		undo_redo.add_do_method(root_node, "add_child", instance)
		undo_redo.add_do_property(instance, "owner", scene_root)
		undo_redo.add_do_reference(instance)
		# does it leak? it should be freed automatically but i'm not sure
		undo_redo.add_undo_method(root_node, "remove_child", instance)
		undo_redo.commit_action()

		instance.global_position = position
		instance.global_rotation = brush.rotation

func set_align_to_surface(value: bool) -> void:
	align_to_surface = value
