@tool
extends Node

signal menu_item_selected(command: String)

const MENU_TEXT = "Format"
const MENU_ITEMS = {
	"format_script": "Format Current Script",
	"lint_script": "Lint Current Script",
	"reorder_code": "Reorder Code",
}

var menu_button: MenuButton = null
var popup_menu: PopupMenu = null


func _ready() -> void:
	var script_editor := EditorInterface.get_script_editor()
	var last_menu_button := _find_last_menu_button(script_editor)
	if not is_instance_valid(last_menu_button):
		push_warning("GDScript Formatter: Could not find valid menu button in script editor. Menu will not be available. Use the command palette instead.")
		return

	menu_button = MenuButton.new()
	menu_button.text = MENU_TEXT
	menu_button.flat = true

	popup_menu = menu_button.get_popup()
	_populate_menu()

	popup_menu.id_pressed.connect(_on_menu_item_pressed)
	last_menu_button.add_sibling(menu_button)


func remove_formatter_menu() -> void:
	if is_instance_valid(menu_button):
		if is_instance_valid(popup_menu):
			popup_menu.id_pressed.disconnect(_on_menu_item_pressed)
		menu_button.queue_free()
		menu_button = null
		popup_menu = null


func update_menu() -> void:
	if not is_instance_valid(popup_menu):
		return
	popup_menu.clear()
	_populate_menu()


func _find_last_menu_button(script_editor: Control) -> MenuButton:
	if script_editor.get_child_count() == 0:
		return null

	var main_container := script_editor.get_child(0)
	if not is_instance_valid(main_container) or not main_container is VBoxContainer:
		return null

	if main_container.get_child_count() == 0:
		return null

	var menu_bar := main_container.get_child(0)
	if not is_instance_valid(menu_bar) or not menu_bar is HBoxContainer:
		return null

	var last_menu_button: MenuButton = null
	for child in menu_bar.get_children():
		if child is MenuButton:
			last_menu_button = child as MenuButton

	return last_menu_button


func _populate_menu() -> void:
	if not is_instance_valid(popup_menu):
		return

	var current_item_index := 0

	popup_menu.add_item(MENU_ITEMS["format_script"], current_item_index)
	popup_menu.set_item_metadata(current_item_index, "format_script")
	popup_menu.set_item_tooltip(current_item_index, "Run the GDScript Formatter over the current script")
	current_item_index += 1

	popup_menu.add_item(MENU_ITEMS["lint_script"], current_item_index)
	popup_menu.set_item_metadata(current_item_index, "lint_script")
	popup_menu.set_item_tooltip(current_item_index, "Check the current script for linting issues")
	current_item_index += 1

	popup_menu.add_item(MENU_ITEMS["reorder_code"], current_item_index)
	popup_menu.set_item_metadata(current_item_index, "reorder_code")
	popup_menu.set_item_tooltip(current_item_index, "Reorder the code elements in the current script according to the GDScript Style Guide")
	current_item_index += 1


func _on_menu_item_pressed(id: int) -> void:
	if not is_instance_valid(popup_menu):
		return

	var command: String = popup_menu.get_item_metadata(id)
	if not command.is_empty():
		menu_item_selected.emit(command)
