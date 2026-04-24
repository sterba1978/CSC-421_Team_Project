extends Control

signal tab_selected(clue_text: String)

const PAGE_FLIP_SFX := preload("res://assets/audio/freesound_community-page-flip-99838.mp3")
const DEFAULT_FOLDER_COVER_TEXTURE := preload("res://assets/folder.png")

@onready var player = $"../InteriorPlayer"
@onready var folder_texture: TextureRect = get_node_or_null("FileFrame/FileCanvas/TextureRect")
@onready var return_button: Button = get_node_or_null("ReturnButton")

@export var tab_1_texture: Texture2D
@export var tab_2_texture: Texture2D
@export var tab_3_texture: Texture2D
@export var folder_cover_texture: Texture2D = DEFAULT_FOLDER_COVER_TEXTURE
@export var tab_1_title: String = "Social Media Impersonation"
@export_multiline var tab_1_text: String = "Fake profiles impersonate friends or brands to request money or information."
@export var tab_2_title: String = "Phishing"
@export_multiline var tab_2_text: String = "Fraudulent messages impersonate trusted sources to steal passwords or financial information."
@export var tab_3_title: String = "Spyware"
@export_multiline var tab_3_text: String = "Hidden malware secretly monitors activity, captures data, and can expose sensitive information."
@export var page_flip_sfx_volume_db: float = -4.0

signal tab_opened # dialog signal
signal folder_closed # dialog signal

@onready var checklist1 = $"../Checklist"
@onready var checklist2 = $"../Checklist2"
@onready var clbackground = $"../ChecklistBackground"

func _ready() -> void:
	_apply_return_button_frame()
	_show_folder_cover()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		_show_folder_cover()


func _on_return_button_pressed() -> void:
	self.hide()
	MusicManager.pop_music()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player._update_crosshair_visibility()
	folder_closed.emit() # dialog signal
	checklist1.show()
	checklist2.show()
	clbackground.show()


func _on_tab_1_pressed() -> void:
	_select_tab(tab_1_texture, tab_1_title, tab_1_text)

func _on_tab_2_pressed() -> void:
	_select_tab(tab_2_texture, tab_2_title, tab_2_text)

func _on_tab_3_pressed() -> void:
	_select_tab(tab_3_texture, tab_3_title, tab_3_text)


func _select_tab(tab_texture: Texture2D, title_text: String, body_text: String) -> void:
	_show_tab(tab_texture, title_text, body_text)
	if visible:
		MusicManager.play_sfx(PAGE_FLIP_SFX, page_flip_sfx_volume_db)
	tab_selected.emit(body_text)
	tab_opened.emit() #dialog signal 


func _show_tab(
	tab_texture: Texture2D,
	_title_text: String,
	_body_text: String
) -> void:
	if folder_texture != null and tab_texture != null:
		folder_texture.texture = tab_texture


func _show_folder_cover() -> void:
	if folder_texture != null and folder_cover_texture != null:
		folder_texture.texture = folder_cover_texture


func _apply_return_button_frame() -> void:
	if return_button == null:
		return

	var normal := _make_button_style(Color(0.02, 0.018, 0.012, 0.82), Color(0.78, 0.72, 0.56, 0.95))
	var hover := _make_button_style(Color(0.08, 0.06, 0.035, 0.92), Color(1.0, 0.88, 0.42, 1.0))
	var pressed := _make_button_style(Color(0.01, 0.01, 0.008, 1.0), Color(1.0, 0.78, 0.25, 1.0))
	return_button.add_theme_stylebox_override("normal", normal)
	return_button.add_theme_stylebox_override("hover", hover)
	return_button.add_theme_stylebox_override("pressed", pressed)
	return_button.add_theme_stylebox_override("disabled", normal)


func _make_button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
