# =============================================================================
# AudioManager.gd — Autoload singleton for all audio playback
# =============================================================================
# Manages background music and SFX. Uses a pool of AudioStreamPlayers to allow
# overlapping sounds. Preferences (music/sfx enabled) are persisted via SaveData.
# Audio files are placeholder paths — drop real files into assets/audio/ to activate.
# =============================================================================
extends Node

const MUSIC_PATH   := "res://assets/audio/music_bg.ogg"
const SFX_PATHS := {
	"slide":    "res://assets/audio/sfx_slide.wav",
	"invalid":  "res://assets/audio/sfx_invalid.wav",
	"reset":    "res://assets/audio/sfx_reset.wav",
	"win":      "res://assets/audio/sfx_win.wav",
	"teleport": "res://assets/audio/sfx_teleport.wav",
	"destroy":  "res://assets/audio/sfx_destroy.wav",
	"click":    "res://assets/audio/click.wav",
}

const MUSIC_VOLUME   := -12.0  # target music volume in dB
const MUSIC_FADE_IN  := 1.6   # fade-in duration in seconds
const SFX_POOL_SIZE  := 4

var _music_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_streams: Dictionary = {}   # String -> AudioStream

var _music_enabled: bool = true
var _sfx_enabled:   bool = true


func _ready() -> void:
	_music_enabled = SaveData.get_music_enabled()
	_sfx_enabled   = SaveData.get_sfx_enabled()

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -80.0  # start silent for fade-in
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = -6.0
		add_child(p)
		_sfx_pool.append(p)

	# Preload SFX streams
	for key in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_sfx_streams[key] = load(path)
		else:
			push_warning("AudioManager: missing SFX file '%s'" % path)

	# Preload and start music
	if ResourceLoader.exists(MUSIC_PATH):
		var stream := load(MUSIC_PATH) as AudioStream
		if stream:
			_music_player.stream = stream
			# AudioStreamOggVorbis and AudioStreamMP3 use .loop; AudioStreamWAV uses .loop_mode
			if stream.has_method("set_loop") or "loop" in stream:
				stream.loop = true
			if _music_enabled:
				_fade_in_music()
	else:
		push_warning("AudioManager: missing music file '%s'" % MUSIC_PATH)


func _fade_in_music() -> void:
	_music_player.volume_db = -80.0
	_music_player.play()
	var tween := create_tween()
	tween.tween_property(_music_player, "volume_db", MUSIC_VOLUME, MUSIC_FADE_IN) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func play_music() -> void:
	if _music_enabled and _music_player.stream and not _music_player.playing:
		_fade_in_music()


func stop_music() -> void:
	_music_player.stop()


func get_sfx_duration(sfx_name: String) -> float:
	if not _sfx_streams.has(sfx_name):
		return 0.0
	return _sfx_streams[sfx_name].get_length()


func play_sfx(sfx_name: String) -> void:
	if not _sfx_enabled:
		return
	if not _sfx_streams.has(sfx_name):
		return
	# Find an idle player in the pool
	for p in _sfx_pool:
		if not p.playing:
			p.stream = _sfx_streams[sfx_name]
			p.play()
			return
	# All busy — reuse the first one
	_sfx_pool[0].stream = _sfx_streams[sfx_name]
	_sfx_pool[0].play()


func set_music_enabled(on: bool) -> void:
	_music_enabled = on
	SaveData.set_music_enabled(on)
	if on:
		play_music()
	else:
		stop_music()


func set_sfx_enabled(on: bool) -> void:
	_sfx_enabled = on
	SaveData.set_sfx_enabled(on)


func is_music_enabled() -> bool:
	return _music_enabled


func is_sfx_enabled() -> bool:
	return _sfx_enabled
