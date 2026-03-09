extends Node3D

@export var exterior_player_path: NodePath = ^"ExteriorPlayer"
@export var interior_player_path: NodePath = ^"InteriorPlayer"
@export var building_door_path: NodePath = ^"Building_door"
@export var interior_transition_delay_sec: float = 0.4
@export var look_mouse_sensitivity: float = 0.0015
@export var journal_title: String = "Journal"
@export var journal_default_text: String = "No item selected yet."

@onready var _exterior_player: Node = get_node_or_null(exterior_player_path)
@onready var _interior_player: Node = get_node_or_null(interior_player_path)
@onready var _building_door: Node = get_node_or_null(building_door_path)

var _transition_queued: bool = false
var _journal_entry_label: Label

## Canvas UI's
@onready var clueboardUI = $ClueBoardUI
@onready var clueUI = $Clue_UI


func _ready() -> void:
	if _building_door != null and _building_door.has_signal("door_opened"):
		_building_door.door_opened.connect(_on_building_door_opened)
	elif _building_door != null and _building_door.has_signal("door_state_changed"):
		# Fallback for older door scripts: switches immediately when state becomes open.
		_building_door.door_state_changed.connect(_on_building_door_state_changed)
	else:
		push_warning("main_flow.gd: Building_door missing or has no door_opened/door_state_changed signal.")

	_set_active_player(_exterior_player)
	_apply_mouse_sensitivity()
	
	## Hiding UI's
	clueboardUI.hide()
	clueUI.hide()

	_ensure_journal_ui()
	_set_journal_entry(journal_default_text)

	if clueboardUI != null and clueboardUI.has_signal("clue_selected"):
		clueboardUI.clue_selected.connect(_on_clue_selected)


func _on_building_door_opened() -> void:
	if _transition_queued:
		return
	_transition_queued = true
	if interior_transition_delay_sec > 0.0:
		await get_tree().create_timer(interior_transition_delay_sec).timeout
	_set_active_player(_interior_player)
	_transition_queued = false


func _on_building_door_state_changed(is_open: bool) -> void:
	if is_open:
		_set_active_player(_interior_player)


func _set_active_player(active: Node) -> void:
	_set_player_enabled(_exterior_player, false)
	_set_player_enabled(_interior_player, false)
	_set_player_enabled(active, true)

	var active_camera := _get_player_camera(active)
	if active_camera != null:
		active_camera.make_current()


func _set_player_enabled(player: Node, enabled: bool) -> void:
	if player == null:
		return

	if player.has_method("set_player_enabled"):
		player.set_player_enabled(enabled)
	else:
		player.set_process_unhandled_input(enabled)


func _get_player_camera(player: Node) -> Camera3D:
	if player == null:
		return null

	if player.has_method("get_camera"):
		return player.get_camera() as Camera3D

	var pivot := player.get_node_or_null("PitchPivot")
	if pivot == null:
		return null

	for child in pivot.get_children():
		if child is Camera3D:
			return child as Camera3D

	return null


func _apply_mouse_sensitivity() -> void:
	for player in [_exterior_player, _interior_player]:
		if player == null:
			continue
		if _has_property(player, "mouse_sensitivity"):
			player.mouse_sensitivity = look_mouse_sensitivity


func _ensure_journal_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "JournalHUD"
	add_child(layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var panel := PanelContainer.new()
	panel.name = "JournalPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 1.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -360.0
	panel.offset_top = 24.0
	panel.offset_right = -24.0
	panel.offset_bottom = 176.0
	root.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	panel.add_child(content)

	var title := Label.new()
	title.text = journal_title
	content.add_child(title)

	_journal_entry_label = Label.new()
	_journal_entry_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_journal_entry_label)


func _set_journal_entry(entry_text: String) -> void:
	if _journal_entry_label != null:
		_journal_entry_label.text = entry_text


func _on_clue_selected(clue_text: String) -> void:
	_set_journal_entry(clue_text)


func _has_property(node: Object, property_name: String) -> bool:
	for prop in node.get_property_list():
		if prop.get("name", "") == property_name:
			return true
	return false
