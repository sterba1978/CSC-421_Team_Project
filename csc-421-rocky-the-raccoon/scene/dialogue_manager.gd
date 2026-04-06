extends Node

@export var dialogue_resource : DialogueResource
@export var dialogue_part2 : String = "tutorial2"

@onready var filingcabinet = $"../FilingCabinet"
var filingopencount = 0


func _ready() -> void:
	print("filingcabinet:", filingcabinet)
	filingcabinet.filing_opened.connect(_on_filing_opened)
	
func _on_filing_opened():
	filingopencount += 1
	if filingopencount == 1:
		print("count is 1")
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_part2)
