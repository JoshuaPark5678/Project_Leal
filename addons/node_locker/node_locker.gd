@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_tool_menu_item("Lock Selected Nodes", _lock_selected)
	add_tool_menu_item("Unlock Selected Nodes", _unlock_selected)

func _exit_tree() -> void:
	remove_tool_menu_item("Lock Selected Nodes")
	remove_tool_menu_item("Unlock Selected Nodes")

func _lock_selected() -> void:
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		node.set_meta("_edit_lock_", true)

func _unlock_selected() -> void:
	var selected = get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		if node.has_meta("_edit_lock_"):
			node.remove_meta("_edit_lock_")
