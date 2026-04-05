extends Node

var _start_in_office := false
var _fade_in_from_black := false


func reset() -> void:
	_start_in_office = false
	_fade_in_from_black = false


func request_office_entry(fade_in_from_black: bool = true) -> void:
	_start_in_office = true
	_fade_in_from_black = fade_in_from_black


func ensure_office_entry(fade_in_from_black: bool = false) -> void:
	_start_in_office = true
	if fade_in_from_black:
		_fade_in_from_black = true


func consume_start_in_office() -> bool:
	var next_value := _start_in_office
	_start_in_office = false
	return next_value


func consume_fade_in_from_black() -> bool:
	var next_value := _fade_in_from_black
	_fade_in_from_black = false
	return next_value
