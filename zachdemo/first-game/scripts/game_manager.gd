extends Node

var score = 0
@onready var scorelabel: Label = $"../Player/Camera2D/scorelabel"

func add_point():
	score += 1
	scorelabel.text = str(score) + "/1"
