extends Control

signal tab_selected(clue_text: String)

@onready var player = $"../InteriorPlayer"
@onready var folder_texture: TextureRect = get_node_or_null("FileFrame/FileCanvas/TextureRect")

@export var tab_1_texture: Texture2D
@export var tab_2_texture: Texture2D
@export var tab_3_texture: Texture2D
@export var tab_1_title: String = "Social Media Impersonation"
@export_multiline var tab_1_text: String = "Fake profiles impersonate friends or brands to request money or information."
@export var tab_2_title: String = "Phishing"
@export_multiline var tab_2_text: String = "Fraudulent messages impersonate trusted sources to steal passwords or financial information."
@export var tab_3_title: String = "Spyware"
@export_multiline var tab_3_text: String = "Hidden malware secretly monitors activity, captures data, and can expose sensitive information."

func _ready() -> void:
	_show_tab(tab_1_texture, tab_1_title, tab_1_text)


func _on_return_button_pressed() -> void:
	self.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player._update_crosshair_visibility()


func _on_tab_1_pressed() -> void:
	_show_tab(tab_1_texture, tab_1_title, tab_1_text)
	tab_selected.emit(tab_1_text)

func _on_tab_2_pressed() -> void:
	_show_tab(tab_2_texture, tab_2_title, tab_2_text)
	tab_selected.emit(tab_2_text)

func _on_tab_3_pressed() -> void:
	_show_tab(tab_3_texture, tab_3_title, tab_3_text)
	tab_selected.emit(tab_3_text)


func _show_tab(
	tab_texture: Texture2D,
	title_text: String,
	body_text: String
) -> void:
	if folder_texture != null and tab_texture != null:
		folder_texture.texture = tab_texture
