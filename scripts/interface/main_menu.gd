extends Control
@onready var profile_label: Label = $Margin/RootVBox/Header/ProfileBox/ProfileLabel
@onready var operative_label: Label = $Margin/RootVBox/ContentHBox/LeftPanel/VBox/OperativeInfo
@onready var diff_option: OptionButton = $Margin/RootVBox/ContentHBox/RightPanel/VBox/DifficultyOption
@onready var quality_option: OptionButton = $Margin/RootVBox/ContentHBox/RightPanel/VBox/QualityOption
@onready var sens_slider: HSlider = $Margin/RootVBox/ContentHBox/RightPanel/VBox/SensSlider
@onready var preview_holder: Node3D = $Margin/RootVBox/ContentHBox/CenterPreview/SubViewportContainer/SubViewport/PreviewStage/OperativeAnchor
var operatives := [
	{"id": "vanguard_m", "name": "CMDR. KAEL VANCE (VANGUARD)", "path": "res://assets/characters/operative_vanguard_m.glb"},
	{"id": "spectre_f", "name": "AGT. LYRA NOVA (SPECTRE)", "path": "res://assets/characters/operative_spectre_f.glb"},
	{"id": "phantom_r", "name": "OPR. DRAKE ZERO (PHANTOM)", "path": "res://assets/characters/operative_phantom_rival.glb"}
]
var op_index: int = 0
func _ready() -> void:
	AudioManager.play_music("menu")
	GraphicsManager.apply_quality(int(SaveSystem.data["settings"]["quality_preset"]))
	diff_option.clear(); diff_option.add_item("DIFICULDADE: RECRUTA", 0); diff_option.add_item("DIFICULDADE: OPERADOR", 1); diff_option.add_item("DIFICULDADE: VETERANO", 2); diff_option.select(1)
	quality_option.clear(); quality_option.add_item("GRÁFICOS: BAIXA", 0); quality_option.add_item("GRÁFICOS: MÉDIA", 1); quality_option.add_item("GRÁFICOS: ALTA", 2); quality_option.add_item("GRÁFICOS: ULTRA", 3); quality_option.select(int(SaveSystem.data["settings"]["quality_preset"]))
	sens_slider.value = float(SaveSystem.data["settings"]["touch_sensitivity"])
	profile_label.text = "%s  |  NÍVEL %d (%d XP)  |  MARCAÇÕES: %d" % [SaveSystem.data["player_name"], int(SaveSystem.data["level"]), int(SaveSystem.data["xp"]), int(SaveSystem.data["total_marks"])]
	_load_preview()
func _process(delta: float) -> void:
	if preview_holder: preview_holder.rotate_y(delta * 0.65)
func _load_preview() -> void:
	for c in preview_holder.get_children(): c.queue_free()
	var e: Dictionary = operatives[op_index]
	operative_label.text = e["name"]; SaveSystem.data["selected_operative"] = e["id"]; SaveSystem.save_game()
	var p: PackedScene = load(e["path"])
	if p: preview_holder.add_child(p.instantiate())
func _on_next_operative_pressed() -> void: AudioManager.play_sfx("click"); op_index = (op_index + 1) % operatives.size(); _load_preview()
func _on_start_campaign_pressed() -> void: AudioManager.play_sfx("click"); GameManager.start_match(GameManager.GameMode.CAMPAIGN, diff_option.selected)
func _on_start_bots_pressed() -> void: AudioManager.play_sfx("click"); GameManager.start_match(GameManager.GameMode.MULTIPLAYER_BOTS, diff_option.selected)
func _on_quality_selected(idx: int) -> void: AudioManager.play_sfx("click"); GraphicsManager.apply_quality(idx)
func _on_sens_changed(val: float) -> void: SaveSystem.data["settings"]["touch_sensitivity"] = val; SaveSystem.save_game()
