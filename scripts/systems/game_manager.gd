extends Node
enum GameMode { CAMPAIGN, MULTIPLAYER_BOTS }
enum Difficulty { RECRUTA, OPERADOR, VETERANO }
var current_mode: GameMode = GameMode.MULTIPLAYER_BOTS
var current_difficulty: Difficulty = Difficulty.OPERADOR
var alpha_score: int = 0
var omega_score: int = 0
var target_score: int = 15
var match_time_remaining: float = 180.0
var is_match_active: bool = false
var player_marks: int = 0
var player_tagged_count: int = 0
var last_match_victory: bool = false
var campaign_nodes_hacked: int = 0
var campaign_nodes_total: int = 3
signal score_updated(alpha: int, omega: int)
signal objective_updated(current: int, total: int)
signal match_ended(victory: bool)

func start_match(mode: GameMode, difficulty: Difficulty = Difficulty.OPERADOR) -> void:
	current_mode = mode; current_difficulty = difficulty
	alpha_score = 0; omega_score = 0; player_marks = 0; player_tagged_count = 0; campaign_nodes_hacked = 0
	match_time_remaining = 240.0 if mode == GameMode.CAMPAIGN else 180.0
	target_score = 12 if mode == GameMode.CAMPAIGN else 15
	is_match_active = true
	get_tree().change_scene_to_file("res://scenes/maps/complexo_urbano.tscn")

func _process(delta: float) -> void:
	if not is_match_active: return
	match_time_remaining -= delta
	if match_time_remaining <= 0.0:
		match_time_remaining = 0.0
		finish_match(alpha_score >= omega_score)

func register_tag(attacker_team: String, is_player: bool = false) -> void:
	if not is_match_active: return
	if attacker_team == "ALPHA":
		alpha_score += 1
		if is_player: player_marks += 1; AudioManager.play_sfx("marked")
	else: omega_score += 1
	score_updated.emit(alpha_score, omega_score)
	if current_mode == GameMode.MULTIPLAYER_BOTS:
		if alpha_score >= target_score: finish_match(true)
		elif omega_score >= target_score: finish_match(false)

func register_terminal_hacked() -> void:
	if not is_match_active: return
	campaign_nodes_hacked += 1; alpha_score += 3
	score_updated.emit(alpha_score, omega_score)
	objective_updated.emit(campaign_nodes_hacked, campaign_nodes_total)
	if current_mode == GameMode.CAMPAIGN and campaign_nodes_hacked >= campaign_nodes_total: finish_match(true)

func finish_match(victory: bool) -> void:
	if not is_match_active: return
	is_match_active = false; last_match_victory = victory
	SaveSystem.data["matches_played"] = int(SaveSystem.data["matches_played"]) + 1
	SaveSystem.data["total_marks"] = int(SaveSystem.data["total_marks"]) + player_marks
	if victory: SaveSystem.data["matches_won"] = int(SaveSystem.data["matches_won"]) + 1; AudioManager.play_sfx("victory", 0.0)
	else: AudioManager.play_sfx("defeat", 0.0)
	SaveSystem.add_xp((player_marks * 45) + (250 if victory else 80))
	match_ended.emit(victory)
	get_tree().change_scene_to_file("res://scenes/menus/results_screen.tscn")
