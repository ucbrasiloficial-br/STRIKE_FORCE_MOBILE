extends Node
var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var streams := {
	"menu": preload("res://assets/audio/menu_theme.wav"),
	"campaign": preload("res://assets/audio/campaign_ambient.wav"),
	"pulse": preload("res://assets/audio/energy_pulse.wav"),
	"marked": preload("res://assets/audio/target_marked.wav"),
	"click": preload("res://assets/audio/ui_click.wav"),
	"step": preload("res://assets/audio/footstep.wav"),
	"victory": preload("res://assets/audio/victory_stinger.wav"),
	"defeat": preload("res://assets/audio/defeat_stinger.wav")
}
func _ready() -> void:
	music_player = AudioStreamPlayer.new(); add_child(music_player)
	for i in range(8):
		var p := AudioStreamPlayer.new(); add_child(p); sfx_pool.append(p)
func play_music(track_name: String) -> void:
	if not streams.has(track_name): return
	var st: AudioStream = streams[track_name]
	if music_player.stream == st and music_player.playing: return
	music_player.stream = st
	music_player.volume_db = linear_to_db(float(SaveSystem.data["settings"]["music_volume"]) * float(SaveSystem.data["settings"]["master_volume"]))
	music_player.play()
func play_sfx(sfx_name: String, pitch_jitter: float = 0.04) -> void:
	if not streams.has(sfx_name): return
	for p in sfx_pool:
		if not p.playing:
			p.stream = streams[sfx_name]
			p.pitch_scale = randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
			p.volume_db = linear_to_db(float(SaveSystem.data["settings"]["sfx_volume"]) * float(SaveSystem.data["settings"]["master_volume"]))
			p.play(); return
