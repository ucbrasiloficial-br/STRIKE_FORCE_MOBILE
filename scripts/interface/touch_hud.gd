extends CanvasLayer
@onready var score_label: Label = $TopBar/HBox/ScoreLabel
@onready var timer_label: Label = $TopBar/HBox/TimerLabel
@onready var objective_label: Label = $TopBar/HBox/ObjectiveLabel
@onready var shield_bar: ProgressBar = $BottomLeft/ShieldBar
@onready var ammo_label: Label = $BottomRight/AmmoLabel
@onready var hit_marker: Label = $CenterCrosshair/HitMarker
@onready var damage_rect: ColorRect = $DamageOverlay
@onready var interact_btn: Button = $BottomRight/InteractButton
@onready var pause_panel: PanelContainer = $PauseOverlay
@onready var joystick_base: Control = $BottomLeft/JoystickArea
@onready var joystick_knob: ColorRect = $BottomLeft/JoystickArea/Knob
var player: CharacterBody3D = null
var joy_touch_idx: int = -1
var look_touch_idx: int = -1
var joy_center: Vector2 = Vector2.ZERO
var joy_radius: float = 68.0

func _ready() -> void:
	pause_panel.visible = false; interact_btn.visible = false; hit_marker.modulate.a = 0.0; damage_rect.modulate.a = 0.0
	GameManager.score_updated.connect(func(_a, _o): _update_header())
	GameManager.objective_updated.connect(func(_c, _t): _update_header())
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("team_alpha")
	if player:
		player.stats_changed.connect(func(sh, am, ma): shield_bar.value = sh; ammo_label.text = "PULSO %02d / %02d" % [am, ma])
		player.hit_marker_triggered.connect(func(): hit_marker.modulate.a = 1.0)
		player.damage_flash_triggered.connect(func(): damage_rect.modulate.a = 0.42)
		player.interact_prompt_changed.connect(func(v, t): interact_btn.visible = v; interact_btn.text = t)
	_update_header()

func _process(delta: float) -> void:
	timer_label.text = "%02d:%02d" % [int(GameManager.match_time_remaining)/60, int(GameManager.match_time_remaining)%60]
	hit_marker.modulate.a = maxf(0.0, hit_marker.modulate.a - delta * 4.5)
	damage_rect.modulate.a = maxf(0.0, damage_rect.modulate.a - delta * 2.5)

func _input(event: InputEvent) -> void:
	if pause_panel.visible or not player: return
	if event is InputEventScreenTouch:
		if event.pressed:
			var rect := joystick_base.get_global_rect()
			if rect.grow(35.0).has_point(event.position) and joy_touch_idx == -1:
				joy_touch_idx = event.index; joy_center = rect.get_center(); _update_joy(event.position)
			elif event.position.x > get_viewport().get_visible_rect().size.x * 0.42 and look_touch_idx == -1:
				look_touch_idx = event.index
		else:
			if event.index == joy_touch_idx:
				joy_touch_idx = -1; player.move_input = Vector2.ZERO; joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5
			elif event.index == look_touch_idx: look_touch_idx = -1
	elif event is InputEventScreenDrag:
		if event.index == joy_touch_idx: _update_joy(event.position)
		elif event.index == look_touch_idx: player.look_delta += event.relative

func _update_joy(pos: Vector2) -> void:
	var off := pos - joy_center
	if off.length() > joy_radius: off = off.normalized() * joy_radius
	joystick_knob.position = (joystick_base.size - joystick_knob.size) * 0.5 + off
	player.move_input = off / joy_radius

func _update_header() -> void:
	score_label.text = "ALPHA %d  |  %d OMEGA" % [GameManager.alpha_score, GameManager.omega_score]
	objective_label.text = ("CAMPANHA: RELÉS %d/%d" % [GameManager.campaign_nodes_hacked, GameManager.campaign_nodes_total]) if GameManager.current_mode == GameManager.GameMode.CAMPAIGN else ("META: %d MARCAÇÕES" % GameManager.target_score)

func _on_fire_down() -> void:
	if player: player.is_firing_held = true
func _on_fire_up() -> void:
	if player: player.is_firing_held = false
func _on_jump_pressed() -> void:
	if player: player.trigger_jump()
func _on_crouch_pressed() -> void:
	if player: player.toggle_crouch()
func _on_reload_pressed() -> void:
	if player: player.recharge_energy_cell()
func _on_interact_pressed() -> void:
	if player: player.trigger_interact()
func _on_pause_pressed() -> void:
	AudioManager.play_sfx("click"); pause_panel.visible = true; get_tree().paused = true
func _on_resume_pressed() -> void:
	AudioManager.play_sfx("click"); pause_panel.visible = false; get_tree().paused = false
func _on_quit_match_pressed() -> void:
	AudioManager.play_sfx("click"); get_tree().paused = false; GameManager.is_match_active = false
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
