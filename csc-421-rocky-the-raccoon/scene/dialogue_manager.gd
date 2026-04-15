extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_part2 : String = "tutorial2"
@export var dialogue_part3 : String = "tutorial3"
@export var dialogue_part4 : String = "tutorial4"
@export var dialogue_part5 : String = "tutorial5"
@export var dialogue_part6 : String = "tutorial6"
@export var dialogue_part7 : String = "tutorial7"
@export var dialogue_part8 : String = "tutorial8"
@export var dialogue_part9 : String = "tutorial9"
@export var dialogue_part10 : String = "tutorial10"


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
@onready var clue = $"../Clue_UI"
var clueclosed = 0

@onready var checklist = $"../Checklist2"

#@onready var journalui = 
var journalopened = 0
var journalclosed = 0

func _ready() -> void:
	update_checklist("Enter the office")
	filingcabinet.filing_opened.connect(_on_filing_opened)
	folder.tab_opened.connect(_on_filetab_opened)
	folder.folder_closed.connect(_on_folder_closed)
	clueboardobj.clueboard_opened.connect(_on_clueboard_opened)
	clueboard.clue_opened.connect(_on_clue_opened)
	clue.clue_closed.connect(_on_clue_closed)
	clueboard.clueboard_closed.connect(_on_clueboard_closed)
	#journalui.journal_opened.connect(_on_journal_opened)

func _on_filing_opened():
	filingopencount += 1
	if filingopencount == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part2)

func _on_filetab_opened():
	tabopen += 1
	if tabopen == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part3)

func _on_folder_closed():
	folderclosed += 1
	if folderclosed == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part4)
		update_checklist("Open clueboard")
		clueboardobj.add_to_group("interactable")

func _on_clueboard_opened():
	clueboardopened += 1
	if clueboardopened == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part5)

func _on_clue_opened():
	clueopened += 1
	if clueopened == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part6)

func _on_clue_closed():
	clueclosed += 1
	if clueclosed == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part7)

func _on_clueboard_closed():
	clueboardclosed += 1
	if clueboardclosed == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part8)
		update_checklist("Open journal")

func _on_journal_opened():
	journalopened += 1
	if journalopened == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part9)
		update_checklist("")
		
#help lol
func _on_journal_closed():
	journalclosed += 1
	if journalclosed == 1:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part10)
		update_checklist("Open the door")

func update_checklist(newtext):
	checklist.text = newtext
