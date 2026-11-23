extends Node
const SAVE_PATH := "user://strike_force_save.json"
var data := {
	"player_name": "OPERADOR_01", "selected_operative": "vanguard_m",
	"xp": 0, "level": 1, "total_marks": 0, "matches_played": 0, "matches_won": 0,
	"settings": {"quality_preset": 2, "touch_sensitivity": 0.35, "master_volume": 0.85, "sfx_volume": 0.90, "music_volume": 0.65}
}
func _ready() -> void: load_game()
func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data, "	")); f.close()
func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH): save_game(); return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var p = JSON.parse_string(f.get_as_text()); f.close()
		if typeof(p) == TYPE_DICTIONARY: _merge_dict(data, p)
func _merge_dict(t: Dictionary, s: Dictionary) -> void:
	for k in s.keys():
		if t.has(k) and typeof(t[k]) == TYPE_DICTIONARY and typeof(s[k]) == TYPE_DICTIONARY: _merge_dict(t[k], s[k])
		else: t[k] = s[k]
func add_xp(amount: int) -> void:
	data["xp"] = int(data["xp"]) + amount
	data["level"] = 1 + int(data["xp"] / 500)
	save_game()
