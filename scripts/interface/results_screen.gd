extends Control
@onready var title_label: Label = $CenterPanel/VBox/TitleLabel
@onready var stats_label: Label = $CenterPanel/VBox/StatsLabel
func _ready() -> void:
	AudioManager.play_music("menu")
	title_label.text = "OPERAÇÃO CONCLUÍDA — VITÓRIA" if GameManager.last_match_victory else "OPERAÇÃO ENCERRADA — DERROTA"
	stats_label.text = "PLACAR FINAL: ALPHA %d x %d OMEGA
SUAS MARCAÇÕES: %d
NÍVEL ATUAL: %d (%d XP TOTAL)" % [GameManager.alpha_score, GameManager.omega_score, GameManager.player_marks, int(SaveSystem.data["level"]), int(SaveSystem.data["xp"])]
func _on_play_again_pressed() -> void: AudioManager.play_sfx("click"); GameManager.start_match(GameManager.current_mode, GameManager.current_difficulty)
func _on_main_menu_pressed() -> void: AudioManager.play_sfx("click"); get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
