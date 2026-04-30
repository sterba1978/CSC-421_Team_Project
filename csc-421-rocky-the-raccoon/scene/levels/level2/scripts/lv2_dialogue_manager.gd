extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_lv2a : String = "level2a"
@export var dialogue_lv2b : String = "level2b"

@onready var tab1 = $"../tab1"
@onready var tab2 = $"../tab2"
@onready var tab3 = $"../tab3"
@onready var folder = $"../folder"
var tabopen = 0
var folderclosed = 0

@onready var filingcabinet = $"../FilingCabinet"
var filingopencount = 0
@onready var clueboardobj = $"../ClueBoard1"
var clueboardopened = 0
@onready var clueboard = $"../ClueBoardUI"
var clueopened = 0
var clueboardclosed = 0
@onready var clue1 = $"../clue_ui"
var clue1closed = 0
@onready var clue2 = $"../clue_ui2"
var clue2closed = 0
@onready var clue3 = $"../clue_ui3"
var clue3closed = 0

@onready var checklist = $"../Checklist2"
@onready var checklist_background = $"../ChecklistBackground"

const CHECKLIST_CHARS_PER_LINE := 22.0
const CHECKLIST_LINE_HEIGHT := 28.0
const CHECKLIST_BOTTOM_PADDING := 12.0

var _checklist_background_default_bottom := 0.0

@onready var patty = get_node_or_null("../Patty")

var autoload = Autoload
var journal_reviewed_after_clues := false

func _ready() -> void:
	_cache_checklist_layout()
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv2a)
	update_checklist("Investigate your clues and journal")
	clue1.clue1_closed.connect(_on_clue1_closed)
	clue2.clue2_closed.connect(_on_clue2_closed)
	clue3.clue3_closed.connect(_on_clue3_closed)
	if patty != null and patty.has_signal("patty_talk"):
		patty.patty_talk.connect(_on_patty_talk)
	else:
		push_warning("Level 2 DialogueManager: Patty node or patty_talk signal was not found.")
	autoload.dialogue_show_mouse.connect(_showmouse)
	autoload.dialogue_hide_mouse.connect(_hidemouse)

func _on_clue1_closed():
	clue1closed += 1
	_update_character_interaction_state()

func _on_clue2_closed():
	clue2closed += 1
	_update_character_interaction_state()

func _on_clue3_closed():
	clue3closed += 1
	_update_character_interaction_state()

func on_journal_opened_for_case() -> void:
	if _all_clues_reviewed():
		journal_reviewed_after_clues = true
	_update_character_interaction_state()

func _update_character_interaction_state() -> void:
	if _all_clues_reviewed() and journal_reviewed_after_clues:
		if patty == null:
			return
		patty.add_to_group("interactable")
		update_checklist("Talk to Patty when ready")
	elif _all_clues_reviewed():
		if patty != null:
			patty.remove_from_group("interactable")
		update_checklist("Open the journal and review the case")

func _all_clues_reviewed() -> bool:
	return clue1closed >= 1 and clue2closed >= 1 and clue3closed >= 1

func _on_patty_talk():
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_lv2b)

func update_checklist(newtext):
	checklist.text = newtext
	_resize_checklist_panel(newtext)


func _cache_checklist_layout() -> void:
	if checklist_background != null:
		_checklist_background_default_bottom = checklist_background.offset_bottom


func _resize_checklist_panel(text: String) -> void:
	if checklist == null or checklist_background == null:
		return

	var wrapped_line_count: int = max(1, int(ceil(float(text.length()) / CHECKLIST_CHARS_PER_LINE)))
	var required_label_bottom: float = float(checklist.offset_top) + (float(wrapped_line_count) * CHECKLIST_LINE_HEIGHT)
	checklist.offset_bottom = required_label_bottom
	checklist_background.offset_bottom = maxf(_checklist_background_default_bottom, required_label_bottom + CHECKLIST_BOTTOM_PADDING)

func _showmouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _hidemouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
