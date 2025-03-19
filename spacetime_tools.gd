@tool
extends EditorPlugin

var dock

func _enter_tree():
	dock = preload("res://addons/spacetime_client/SpacetimeClientDock.tscn").instantiate()
	# Add the loaded scene to the docks.
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

func _exit_tree():
	remove_control_from_docks(dock)
	dock.free()
