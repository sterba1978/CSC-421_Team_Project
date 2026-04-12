extends CanvasLayer

signal journal_opened
signal journal_closed

@export var case_title: String = "Case Journal"
@export_multiline var case_summary: String = "Open the clue board, collect evidence, and keep your working theory here while you investigate each case."
@export var question_prompts: PackedStringArray = PackedStringArray([
	"Who is the strongest suspect right now?",
	"Which clue feels the most important?",
	"What's your current theory for this case?"
])

@onready var _journal_button: Button = $Root/JournalShortcut/JournalButton
@onready var _overlay: Control = $Root/Overlay
@onready var _clue_count_label: Label = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Body/ClueColumn/ClueColumnMargin/ClueColumnContent/ClueCountLabel
@onready var _clue_list: ItemList = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Body/ClueColumn/ClueColumnMargin/ClueColumnContent/ClueList
@onready var _selected_clue_title: Label = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Body/DetailColumn/DetailColumnMargin/DetailColumnContent/SelectedClueTitle
@onready var _selected_clue_body: RichTextLabel = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Body/DetailColumn/DetailColumnMargin/DetailColumnContent/ClueBodyScroll/SelectedClueBody
@onready var _questions_container: VBoxContainer = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Body/DetailColumn/DetailColumnMargin/DetailColumnContent/QuestionsScroll/QuestionsContainer
@onready var _case_title_label: Label = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Header/HeaderText/CaseTitleLabel
@onready var _case_summary_label: Label = $Root/Overlay/PanelCenter/JournalPanel/PanelMargin/Layout/Header/HeaderText/CaseSummaryLabel

var _shortcut_enabled := true
var _selected_clue_id: String = ""
var _clues: Array[Dictionary] = []
var _question_answers: Array[String] = []
var _question_inputs: Array[Control] = []


func _ready() -> void:
	_case_title_label.text = case_title
	_case_summary_label.text = case_summary
	_overlay.hide()
	_build_question_inputs()
	_refresh_clue_list()
	_sync_shortcut_visibility()


func _unhandled_input(event: InputEvent) -> void:
	if not _overlay.visible:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			close_journal()
			get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _overlay.visible


func set_shortcut_enabled(enabled: bool) -> void:
	_shortcut_enabled = enabled
	_sync_shortcut_visibility()


func open_journal() -> void:
	if _overlay.visible:
		return

	_overlay.show()
	_sync_shortcut_visibility()
	journal_opened.emit()


func close_journal() -> void:
	if not _overlay.visible:
		return

	_overlay.hide()
	_sync_shortcut_visibility()
	journal_closed.emit()


func add_clue(clue_id: String, clue_title: String, clue_text: String) -> void:
	var normalized_id := clue_id.strip_edges()
	if normalized_id.is_empty():
		return

	var normalized_title := clue_title.strip_edges()
	if normalized_title.is_empty():
		normalized_title = "Collected Clue"

	var normalized_text := clue_text.strip_edges()
	if normalized_text.is_empty():
		normalized_text = "No clue details have been recorded for this lead yet."

	var clue_entry := {
		"id": normalized_id,
		"title": normalized_title,
		"text": normalized_text,
	}

	var existing_index := _find_clue_index(normalized_id)
	if existing_index == -1:
		_clues.append(clue_entry)
	else:
		_clues[existing_index] = clue_entry

	_selected_clue_id = normalized_id
	_refresh_clue_list()


func _on_journal_button_pressed() -> void:
	open_journal()


func _on_close_button_pressed() -> void:
	close_journal()


func _on_clue_list_item_selected(index: int) -> void:
	if index < 0 or index >= _clues.size():
		return

	_selected_clue_id = _clues[index].get("id", "")
	_show_clue(index)


func _build_question_inputs() -> void:
	_question_answers.clear()
	_question_inputs.clear()

	for child in _questions_container.get_children():
		child.queue_free()

	for index in range(question_prompts.size()):
		var prompt_label := Label.new()
		prompt_label.text = question_prompts[index]
		prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		prompt_label.add_theme_font_size_override("font_size", 15)
		_questions_container.add_child(prompt_label)

		_question_answers.append("")

		if index == question_prompts.size() - 1:
			var theory_input := TextEdit.new()
			theory_input.custom_minimum_size = Vector2(0.0, 120.0)
			theory_input.placeholder_text = "Write your working theory here..."
			theory_input.text_changed.connect(_on_theory_text_changed.bind(index, theory_input))
			_questions_container.add_child(theory_input)
			_question_inputs.append(theory_input)
		else:
			var answer_input := LineEdit.new()
			answer_input.placeholder_text = "Type your answer..."
			answer_input.text_changed.connect(_on_answer_text_changed.bind(index))
			_questions_container.add_child(answer_input)
			_question_inputs.append(answer_input)


func _on_answer_text_changed(new_text: String, index: int) -> void:
	if index < 0 or index >= _question_answers.size():
		return

	_question_answers[index] = new_text


func _on_theory_text_changed(index: int, source: TextEdit) -> void:
	if index < 0 or index >= _question_answers.size():
		return

	_question_answers[index] = source.text


func _refresh_clue_list() -> void:
	_clue_list.clear()

	for clue in _clues:
		_clue_list.add_item(clue.get("title", "Collected Clue"))

	var clue_count := _clues.size()
	var clue_label := "clue" if clue_count == 1 else "clues"
	_clue_count_label.text = "%d %s collected" % [clue_count, clue_label]

	if _clues.is_empty():
		_selected_clue_title.text = "No clues collected yet"
		_selected_clue_body.text = "Inspect the clue board and click into a clue to add it to this journal."
		return

	var selected_index := _find_clue_index(_selected_clue_id)
	if selected_index == -1:
		selected_index = 0
		_selected_clue_id = _clues[0].get("id", "")

	_clue_list.select(selected_index)
	_show_clue(selected_index)


func _show_clue(index: int) -> void:
	if index < 0 or index >= _clues.size():
		return

	var clue := _clues[index]
	_selected_clue_title.text = clue.get("title", "Collected Clue")
	_selected_clue_body.text = clue.get("text", "")


func _find_clue_index(clue_id: String) -> int:
	for index in range(_clues.size()):
		if _clues[index].get("id", "") == clue_id:
			return index
	return -1


func _sync_shortcut_visibility() -> void:
	_journal_button.visible = _shortcut_enabled and not _overlay.visible
	_journal_button.disabled = not _shortcut_enabled
