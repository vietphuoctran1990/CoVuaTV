extends Node
## Cài đặt gia đình — lưu user://settings.cfg

var hints_enabled: bool = true
var undo_enabled: bool = true
var max_undos: int = 3
var sfx_enabled: bool = true
var music_enabled: bool = true
var ai_difficulty: int = 0  # 0 easy, 1 medium
var learn_mode: bool = true  # chỉ highlight nước hợp lệ + hiện gợi ý luật

const PATH := "user://settings.cfg"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	hints_enabled = cfg.get_value("game", "hints", true)
	undo_enabled = cfg.get_value("game", "undo", true)
	max_undos = cfg.get_value("game", "max_undos", 3)
	sfx_enabled = cfg.get_value("audio", "sfx", true)
	music_enabled = cfg.get_value("audio", "music", true)
	ai_difficulty = cfg.get_value("game", "ai_difficulty", 0)
	learn_mode = cfg.get_value("game", "learn_mode", true)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "hints", hints_enabled)
	cfg.set_value("game", "undo", undo_enabled)
	cfg.set_value("game", "max_undos", max_undos)
	cfg.set_value("audio", "sfx", sfx_enabled)
	cfg.set_value("audio", "music", music_enabled)
	cfg.set_value("game", "ai_difficulty", ai_difficulty)
	cfg.set_value("game", "learn_mode", learn_mode)
	cfg.save(PATH)
