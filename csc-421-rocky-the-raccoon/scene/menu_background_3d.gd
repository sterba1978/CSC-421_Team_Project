extends Node3D

@export var sign_light_on_energy: float = 15.0
@export var door_light_on_energy: float = 48.0
@export var sign_glow_on_energy: float = 1.15
@export var bulb_glow_on_energy: float = 26.0
@export var door_light_dim_energy: float = 6.0
@export var door_light_flicker_speed: float = 4.0

@onready var _sign_light_spot: SpotLight3D = get_node_or_null("Environment2/Exterior/StreetLamp/SignLight/SpotLight3D")
@onready var _door_light_spot: SpotLight3D = get_node_or_null("Environment2/Exterior/StreetLamp/MeshInstance3D/SpotLight3D")

var _time := 0.0


func _ready() -> void:
	randomize()
	_apply_sign_light_state()


func _process(_delta: float) -> void:
	_time += _delta
	_apply_door_light_flicker()


func _apply_sign_light_state() -> void:
	if _sign_light_spot != null:
		_sign_light_spot.light_energy = sign_light_on_energy


func _apply_door_light_flicker() -> void:
	var flicker_pattern := 0.92
	flicker_pattern += sin(_time * door_light_flicker_speed) * 0.06
	flicker_pattern += sin((_time * door_light_flicker_speed * 1.73) + 0.8) * 0.04

	var short_dip := pow(max(0.0, sin((_time * door_light_flicker_speed * 2.2) + 0.35)), 18.0) * 0.75
	var deep_dip := pow(max(0.0, sin((_time * door_light_flicker_speed * 0.9) + 1.4)), 30.0) * 0.9
	flicker_pattern -= short_dip
	flicker_pattern -= deep_dip
	flicker_pattern = clamp(flicker_pattern, 0.0, 1.0)

	if _door_light_spot != null:
		_door_light_spot.light_energy = lerp(door_light_dim_energy, door_light_on_energy, flicker_pattern)
