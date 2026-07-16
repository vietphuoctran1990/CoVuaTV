extends Node
## SFX + BGM nhẹ cho TV / trẻ em.

enum Sfx { MOVE, CAPTURE, CHECK, WIN, BONK, PROMOTE, CLICK }

var _sfx_players: Array = []
var _bgm: AudioStreamPlayer
var _streams: Dictionary = {}


func _ready() -> void:
	_streams[Sfx.MOVE] = _load_stream("res://assets/audio/move.wav")
	_streams[Sfx.CAPTURE] = _load_stream("res://assets/audio/capture.wav")
	_streams[Sfx.CHECK] = _load_stream("res://assets/audio/check.wav")
	_streams[Sfx.WIN] = _load_stream("res://assets/audio/win.wav")
	_streams[Sfx.BONK] = _load_stream("res://assets/audio/bonk.wav")
	_streams[Sfx.PROMOTE] = _load_stream("res://assets/audio/promote.wav")
	_streams[Sfx.CLICK] = _load_stream("res://assets/audio/click.wav")

	for i in 6:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_players.append(p)

	_bgm = AudioStreamPlayer.new()
	_bgm.bus = "Master"
	_bgm.volume_db = -10.0
	add_child(_bgm)
	var bgm_stream = _load_stream("res://assets/audio/bgm.wav")
	if bgm_stream:
		# duplicate để không mutate resource import dùng chung
		var stream: AudioStream = bgm_stream.duplicate()
		if stream is AudioStreamWAV:
			var wav := stream as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			if wav.data.size() > 0:
				wav.loop_end = int(wav.data.size() / 2) - 1
		_bgm.stream = stream
	call_deferred("start_bgm")


func _load_stream(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Missing audio: " + path)
	return null


## Tạm tắt phát âm thanh thật — tránh crash driver WASAPI/OpenAL trên một số máy.
## Đặt true để bật lại SFX sau khi ổn định.
const ENABLE_REAL_AUDIO := false


func play(sfx: int) -> void:
	if not ENABLE_REAL_AUDIO:
		return
	if AppSettings == null or not AppSettings.sfx_enabled:
		return
	if not _streams.has(sfx) or _streams[sfx] == null:
		return
	if _sfx_players.is_empty():
		return
	for p in _sfx_players:
		if p == null or not is_instance_valid(p):
			continue
		if not p.playing:
			p.stream = _streams[sfx]
			p.volume_db = 0.0
			p.play()
			return
	var p0: AudioStreamPlayer = _sfx_players[0]
	if p0 != null and is_instance_valid(p0):
		p0.stream = _streams[sfx]
		p0.play()


func start_bgm() -> void:
	if not ENABLE_REAL_AUDIO:
		return
	if AppSettings == null or not AppSettings.music_enabled:
		return
	if _bgm != null and _bgm.stream and not _bgm.playing:
		_bgm.play()


func stop_bgm() -> void:
	if _bgm.playing:
		_bgm.stop()


func update_music_setting() -> void:
	if AppSettings.music_enabled:
		start_bgm()
	else:
		stop_bgm()
