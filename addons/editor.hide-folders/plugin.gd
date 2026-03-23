@tool
extends EditorPlugin

const HIDE_ICON: Texture = preload("res://addons/editor.hide-folders/assets/icons/visibility_x_ray.svg")
const DOT_USER: String = "user://editor/hiddenfolders.dat"
const COLOR_HIDDEN := Color.DARK_GRAY
const COLOR_VISIBLE := Color.WHITE

var _buffer: Dictionary = { }
var _hidden_roots: PackedStringArray = []
var _tree: Tree = null
var _menu_service: EditorContextMenuPlugin = null
var _show_hidden_items: bool = true
var _buttons: Array[Button] = []
var _update_scheduled := false


func _enter_tree() -> void:
	_setup()

	_menu_service = ResourceLoader.load("res://addons/editor.hide-folders/src/menu_item.gd").new()
	_menu_service.ref_plug = self
	_menu_service.hide_folders.connect(_on_hide_cmd)


func _ready() -> void:
	var dock: FileSystemDock = EditorInterface.get_file_system_dock()
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()

	_find_tree(dock)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _menu_service)

	dock.folder_moved.connect(_moved_callback)
	dock.folder_removed.connect(_remove_callback)
	dock.folder_color_changed.connect(_schedule_update)

	fs.filesystem_changed.connect(_schedule_update)
	if _tree:
		_tree.item_collapsed.connect(_on_tree_visibility_changed)
		_tree.item_activated.connect(_on_tree_visibility_changed)
		_tree.item_selected.connect(_on_tree_visibility_changed)

	_schedule_update()

	var containers := find_button_container(dock)
	for container in containers:
		var button := Button.new()

		button.tooltip_text = "Show/Hide Folders hider"
		button.flat = true
		button.icon = HIDE_ICON
		button.toggle_mode = true

		button.toggled.connect(_show_hide_enable)
		button.button_pressed = _show_hidden_items

		container.add_child(button)
		container.move_child(button, container.get_child_count() - 2)

		_buttons.append(button)


func _exit_tree() -> void:
	if is_instance_valid(_menu_service):
		remove_context_menu_plugin(_menu_service)
		_menu_service.ref_plug = null

	var dock: FileSystemDock = EditorInterface.get_file_system_dock()
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()

	if dock.folder_moved.is_connected(_moved_callback):
		dock.folder_moved.disconnect(_moved_callback)

	if dock.folder_removed.is_connected(_remove_callback):
		dock.folder_removed.disconnect(_remove_callback)

	if dock.folder_color_changed.is_connected(_schedule_update):
		dock.folder_color_changed.disconnect(_schedule_update)

	if fs.filesystem_changed.is_connected(_schedule_update):
		fs.filesystem_changed.disconnect(_schedule_update)

	if _tree:
		if _tree.item_collapsed.is_connected(_on_tree_visibility_changed):
			_tree.item_collapsed.disconnect(_on_tree_visibility_changed)
		if _tree.item_activated.is_connected(_on_tree_visibility_changed):
			_tree.item_activated.disconnect(_on_tree_visibility_changed)
		if _tree.item_selected.is_connected(_on_tree_visibility_changed):
			_tree.item_selected.disconnect(_on_tree_visibility_changed)

	var cfg := ConfigFile.new()

	for k: String in _buffer.keys().duplicate():
		if not (DirAccess.dir_exists_absolute(k) or FileAccess.file_exists(k)):
			_buffer.erase(k)

	cfg.set_value("DAT", "PTH", _buffer)
	cfg.set_value("ShowHideItems", "Enabled", _show_hidden_items)

	if cfg.save(DOT_USER) != OK:
		push_warning("Error on save HideFolders!")

	for b in _buttons:
		b.queue_free()


func get_buffer() -> Dictionary:
	return _buffer


func find_button_container(node: Node) -> Array[Container]:
	var containers: Array[Container] = []

	for child in node.get_children():
		if child is MenuButton and child.tooltip_text == tr("Sort Files"):
			containers.append(node)

		for c in find_button_container(child):
			containers.append(c)

	return containers


func _setup() -> void:
	var dir := DOT_USER.get_base_dir()

	if !DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
		return

	if FileAccess.file_exists(DOT_USER):
		var cfg := ConfigFile.new()

		if cfg.load(DOT_USER) != OK:
			return

		_buffer = cfg.get_value("DAT", "PTH", { })
		_show_hidden_items = bool(cfg.get_value("ShowHideItems", "Enabled", true))

	_rebuild_hidden_roots()

#region hidden roots cache
func _rebuild_hidden_roots() -> void:
	_hidden_roots.clear()
	for p: String in _buffer.keys():
		_hidden_roots.append(p)


func _is_path_hidden(path: String) -> bool:
	if _buffer.has(path):
		return true

	for hidden: String in _hidden_roots:
		if path.begins_with(hidden + "/"):
			return true

	return false
#endregion

#region filesystem callbacks
func _moved_callback(old_path: String, new_path: String) -> void:
	if old_path != new_path and _buffer.has(old_path):
		_buffer[new_path] = _buffer[old_path]
		_buffer.erase(old_path)

		_rebuild_hidden_roots()
		_schedule_update()


func _remove_callback(path: String) -> void:
	if _buffer.has(path):
		_buffer.erase(path)
		_rebuild_hidden_roots()
		_schedule_update()
#endregion

func _on_hide_cmd(paths: PackedStringArray) -> void:
	for path: String in paths:
		var is_dir := DirAccess.dir_exists_absolute(path)
		var is_file := FileAccess.file_exists(path)

		if not (is_dir or is_file):
			continue

		if _buffer.has(path):
			_buffer.erase(path)
		else:
			_buffer[path] = false

	if _buffer.has("res://"):
		_buffer.erase("res://")

	_rebuild_hidden_roots()
	_schedule_update()


func _schedule_update() -> void:
	if _update_scheduled:
		return

	_update_scheduled = true
	call_deferred("_run_update")


func _run_update() -> void:
	_update_scheduled = false
	_update_visible_items()


func _update_visible_items() -> void:
	if _tree == null:
		return

	var root: TreeItem = _tree.get_root()
	if root == null:
		return

	var item := root.get_first_child()
	while item:
		_apply_filter(item)
		item = item.get_next()


func _apply_filter(item: TreeItem) -> void:
	var path = item.get_metadata(0)

	if typeof(path) != TYPE_STRING:
		return

	var hidden := _is_path_hidden(path)
	item.visible = not hidden or _show_hidden_items

	if hidden:
		var c := item.get_icon_modulate(0)
		c.a = 0.5

		item.set_icon_overlay(0, HIDE_ICON)
		item.set_custom_color(0, COLOR_HIDDEN)
		item.set_icon_modulate(0, c)
	else:
		var c := item.get_icon_modulate(0)
		c.a = 1.0

		item.set_custom_color(0, COLOR_VISIBLE)
		item.set_icon_overlay(0, null)
		item.set_icon_modulate(0, c)

	var child := item.get_first_child()

	while child:
		_apply_filter(child)
		child = child.get_next()


func _on_tree_visibility_changed(_item = null) -> void:
	_schedule_update()


func _show_hide_enable(toggle: bool) -> void:
	for b in _buttons:
		b.button_pressed = toggle

	_show_hidden_items = toggle
	_schedule_update()

#region tree finder
func _find_tree(n: Node) -> bool:
	if n is Tree:
		var t: TreeItem = n.get_root()

		if t != null:
			t = t.get_first_child()
			while t != null:
				if t.get_metadata(0) == "res://":
					_tree = n
					return true
				t = t.get_next()

	for x in n.get_children():
		if _find_tree(x):
			return true

	return false
#endregion
