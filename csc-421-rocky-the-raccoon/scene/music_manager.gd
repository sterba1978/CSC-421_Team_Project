extends Node

const SILENT_VOLUME_DB: float = -60.0
const MUSIC_CROSSFADE_DURATION_SEC: float = 0.75

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer
var _inactive_music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _music_fade_tween: Tween
var _current_stream: AudioStream
var _current_volume_db: float = -8.0
var _current_start_position_sec: float = 0.0
var _music_stack_streams: Array[AudioStream] = []
var _music_stack_volumes_db: Array[float] = []
var _music_stack_positions_sec: Array[float] = []


func _ready() -> void:
	_music_player_a = _create_music_player("MusicPlayerA")
	_music_player_b = _create_music_player("MusicPlayerB")
	_active_music_player = _music_player_a
	_inactive_music_player = _music_player_b
	add_child(_music_player_a)
	add_child(_music_player_b)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SfxPlayer"
	_sfx_player.bus = &"Master"
	add_child(_sfx_player)

	if not _music_player_a.finished.is_connected(_on_music_player_a_finished):
		_music_player_a.finished.connect(_on_music_player_a_finished)
	if not _music_player_b.finished.is_connected(_on_music_player_b_finished):
		_music_player_b.finished.connect(_on_music_player_b_finished)


func play_music(stream: AudioStream, volume_db: float = -8.0, start_position_sec: float = 0.0, restart: bool = false) -> void:
	if stream == null or _active_music_player == null or _inactive_music_player == null:
		return

	var clamped_start: float = start_position_sec if start_position_sec >= 0.0 else 0.0
	var same_stream: bool = _current_stream == stream
	var same_volume: bool = is_equal_approx(_current_volume_db, volume_db)
	var same_start: bool = is_equal_approx(_current_start_position_sec, clamped_start)

	if not restart and _active_music_player.playing and same_stream and same_volume and same_start:
		return

	_current_stream = stream
	_current_volume_db = volume_db
	_current_start_position_sec = clamped_start

	_cancel_music_fade()

	if _inactive_music_player.playing:
		_inactive_music_player.stop()
		_inactive_music_player.volume_db = SILENT_VOLUME_DB

	if not _active_music_player.playing:
		_play_music_immediately(_active_music_player, stream, volume_db, clamped_start)
		return

	if same_stream:
		_play_music_immediately(_active_music_player, stream, volume_db, clamped_start)
		return

	_crossfade_to_music(stream, volume_db, clamped_start)


func push_music(stream: AudioStream, volume_db: float = -8.0, start_position_sec: float = 0.0) -> void:
	if stream == null:
		return

	if _current_stream != null:
		_music_stack_streams.append(_current_stream)
		_music_stack_volumes_db.append(_current_volume_db)

		var resume_position_sec: float = _current_start_position_sec
		if _active_music_player != null and _active_music_player.playing:
			var playback_position_sec: float = _active_music_player.get_playback_position()
			resume_position_sec = playback_position_sec if playback_position_sec >= 0.0 else _current_start_position_sec

		_music_stack_positions_sec.append(resume_position_sec)

	play_music(stream, volume_db, start_position_sec, true)


func pop_music() -> void:
	if _music_stack_streams.is_empty():
		return

	var last_index: int = _music_stack_streams.size() - 1
	var previous_stream: AudioStream = _music_stack_streams[last_index]
	var previous_volume_db: float = _music_stack_volumes_db[last_index]
	var previous_position_sec: float = _music_stack_positions_sec[last_index]
	_music_stack_streams.remove_at(last_index)
	_music_stack_volumes_db.remove_at(last_index)
	_music_stack_positions_sec.remove_at(last_index)
	play_music(previous_stream, previous_volume_db, previous_position_sec, true)


func stop_music() -> void:
	_cancel_music_fade()
	_current_stream = null
	if _music_player_a != null:
		_music_player_a.stop()
		_music_player_a.volume_db = SILENT_VOLUME_DB
	if _music_player_b != null:
		_music_player_b.stop()
		_music_player_b.volume_db = SILENT_VOLUME_DB


func play_sfx(stream: AudioStream, volume_db: float = -4.0) -> void:
	if _sfx_player == null or stream == null:
		return

	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.play()


func clear_music_stack() -> void:
	_music_stack_streams.clear()
	_music_stack_volumes_db.clear()
	_music_stack_positions_sec.clear()


func _on_music_finished() -> void:
	if _active_music_player == null or _current_stream == null:
		return

	_active_music_player.play(_current_start_position_sec)


func _create_music_player(player_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = &"Master"
	player.volume_db = SILENT_VOLUME_DB
	return player


func _play_music_immediately(player: AudioStreamPlayer, stream: AudioStream, volume_db: float, start_position_sec: float) -> void:
	if player == null or stream == null:
		return

	player.stream = stream
	player.volume_db = volume_db
	player.play(start_position_sec)


func _crossfade_to_music(stream: AudioStream, volume_db: float, start_position_sec: float) -> void:
	var outgoing_player: AudioStreamPlayer = _active_music_player
	var incoming_player: AudioStreamPlayer = _inactive_music_player
	if outgoing_player == null or incoming_player == null:
		return

	incoming_player.stop()
	incoming_player.stream = stream
	incoming_player.volume_db = SILENT_VOLUME_DB
	incoming_player.play(start_position_sec)

	_active_music_player = incoming_player
	_inactive_music_player = outgoing_player

	if MUSIC_CROSSFADE_DURATION_SEC <= 0.0:
		incoming_player.volume_db = volume_db
		outgoing_player.stop()
		outgoing_player.volume_db = SILENT_VOLUME_DB
		return

	var fade_tween: Tween = create_tween()
	_music_fade_tween = fade_tween
	fade_tween.set_parallel(true)
	fade_tween.tween_property(outgoing_player, "volume_db", SILENT_VOLUME_DB, MUSIC_CROSSFADE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(incoming_player, "volume_db", volume_db, MUSIC_CROSSFADE_DURATION_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.finished.connect(_on_music_fade_finished.bind(outgoing_player, incoming_player), CONNECT_ONE_SHOT)


func _cancel_music_fade() -> void:
	if _music_fade_tween != null:
		_music_fade_tween.kill()
		_music_fade_tween = null


func _on_music_fade_finished(outgoing_player: AudioStreamPlayer, incoming_player: AudioStreamPlayer) -> void:
	if _inactive_music_player == outgoing_player:
		outgoing_player.stop()
		outgoing_player.volume_db = SILENT_VOLUME_DB

	if _active_music_player == incoming_player:
		incoming_player.volume_db = _current_volume_db

	_music_fade_tween = null


func _on_music_player_a_finished() -> void:
	_on_music_player_finished(_music_player_a)


func _on_music_player_b_finished() -> void:
	_on_music_player_finished(_music_player_b)


func _on_music_player_finished(player: AudioStreamPlayer) -> void:
	if player == null or player != _active_music_player or _current_stream == null:
		return

	player.play(_current_start_position_sec)
