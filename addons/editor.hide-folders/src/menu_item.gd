extends EditorContextMenuPlugin

signal hide_folders(paths: PackedStringArray)

#region godotengine_repository_icons
const HIDE_ICON: Texture = preload("res://addons/editor.hide-folders/assets/icons/visibility_hidden.svg")
const VISIBLE_ICON: Texture = preload("res://addons/editor.hide-folders/assets/icons/visibility_visible.svg")
const TOGGLE_ICON: Texture = preload("res://addons/editor.hide-folders/assets/icons/visibility_x_ray.svg")

var ref_plug: EditorPlugin = null


func _popup_menu(paths: PackedStringArray) -> void:
	var any_hidden := false
	var any_visible := false
	var has_item := false

	var hidden_buffer: Dictionary = { }

	if is_instance_valid(ref_plug):
		hidden_buffer = ref_plug.get_buffer()

	for p: String in paths:
		var is_dir := DirAccess.dir_exists_absolute(p)
		var is_file := FileAccess.file_exists(p)

		if not (is_dir or is_file):
			continue
		has_item = true

		if hidden_buffer.has(p):
			any_hidden = true
			if any_visible:
				break
		else:
			any_visible = true
			if any_hidden:
				break

	if not has_item:
		return

	var locale: String = OS.get_locale_language()
	var translation: Translation = TranslationServer.get_translation_object(locale)

	if any_visible and any_hidden:
		add_context_menu_item(
			"{0} {1}".format(
				[
					_get_tr(translation, &"Toggle"),
					_get_tr(translation, &"Item"),
				],
			).capitalize(),
			_on_hide_cmd,
			TOGGLE_ICON,
		)
	elif any_visible:
		add_context_menu_item(
			"{0} {1}".format(
				[
					_get_tr(translation, &"Hide"),
					_get_tr(translation, &"Item"),
				],
			).capitalize(),
			_on_hide_cmd,
			VISIBLE_ICON,
		)
	else:
		add_context_menu_item(
			"{0} {1}".format(
				[
					_get_tr(translation, &"Show"),
					_get_tr(translation, &"Item"),
				],
			).capitalize(),
			_on_hide_cmd,
			HIDE_ICON,
		)


func _on_hide_cmd(paths: PackedStringArray) -> void:
	hide_folders.emit(paths)


func _get_tr(translation: Translation, msg: StringName) -> StringName:
	if translation == null:
		return msg

	var new_msg: StringName = translation.get_message(msg)
	if new_msg.is_empty():
		return msg

	return new_msg
#endregion
