extends CharacterBody3D
@export var walk_speed: float = 5.4
@export var sprint_speed: float = 8.2
@export var crouch_speed: float = 3.1
@export var jump_velocity: float = 5.2
@export var max_shield: float = 100.0
var shield: float = 100.0
var energy_ammo: int = 30
var max_energy_ammo: int = 30
var is_crouching: bool = false
var is_recharging: bool = false
var fire_cooldown: float = 0.0
var step_timer: float = 0.0
var team: String = "ALPHA"
var spawn_point: Vector3 = Vector3(0.0, 1.2, 24.0)
var move_input: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var is_firing_held: bool = false
var nearby_terminal: Node = null

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var marker_mount: Node3D = $Head/Camera3D/MarkerMount
@onready var pulse_ray: RayCast3D = $Head/Camera3D/PulseRay
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/MarkerMount/MuzzleLight
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

signal stats_changed(shield_val: float, ammo_val: int, max_ammo: int)
signal hit_marker_triggered
signal damage_flash_triggered
signal interact_prompt_changed(visible_flag: bool, prompt_text: String)

func _ready() -> void:
	add_to_group("combatants"); add_to_group("team_alpha")
	spawn_point = global_position
	camera.far = GraphicsManager.get_render_distance()
	stats_changed.emit(shield, energy_ammo, max_energy_ammo)

func _physics_process(delta: float) -> void:
	if not GameManager.is_match_active: return
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	muzzle_flash.light_energy = maxf(0.0, muzzle_flash.light_energy - delta * 24.0)
	if shield < max_shield:
		shield = minf(max_shield, shield + delta * 6.5)
		stats_changed.emit(shield, energy_ammo, max_energy_ammo)
	var sens: float = float(SaveSystem.data["settings"]["touch_sensitivity"]) * 0.008
	if look_delta.length_squared() > 0.0:
		rotate_y(-look_delta.x * sens)
		head.rotate_x(-look_delta.y * sens)
		head.rotation.x = clampf(head.rotation.x, deg_to_rad(-82.0), deg_to_rad(82.0))
		look_delta = Vector2.ZERO
	if not is_on_floor(): velocity += get_gravity() * delta
	var kb_input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var final_input := move_input if move_input.length() > 0.05 else kb_input
	var speed := crouch_speed if is_crouching else (sprint_speed if final_input.y < -0.82 else walk_speed)
	var direction := (transform.basis * Vector3(final_input.x, 0.0, final_input.y)).normalized()
	if direction:
		velocity.x = direction.x * speed; velocity.z = direction.z * speed
		if is_on_floor():
			step_timer -= delta * (speed / walk_speed)
			if step_timer <= 0.0: step_timer = 0.44; AudioManager.play_sfx("step", 0.12)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
	var sway_target := Vector3(0.22 + sin(Time.get_ticks_msec()*0.008)*0.008*final_input.length(), -0.20 + abs(cos(Time.get_ticks_msec()*0.008))*0.008*final_input.length(), -0.38)
	marker_mount.position = marker_mount.position.lerp(sway_target, delta * 12.0)
	head.position.y = lerpf(head.position.y, 1.05 if is_crouching else 1.62, delta * 10.0)
	move_and_slide()
	if is_firing_held or Input.is_action_pressed("ui_accept"): fire_energy_pulse()

func trigger_jump() -> void:
	if is_on_floor(): velocity.y = jump_velocity
func toggle_crouch() -> void:
	is_crouching = not is_crouching
	var cap := collision_shape.shape as CapsuleShape3D
	if cap: cap.height = 1.25 if is_crouching else 1.80
func trigger_interact() -> void:
	if nearby_terminal and nearby_terminal.has_method("activate_terminal"): nearby_terminal.activate_terminal()
func set_nearby_terminal(term: Node) -> void:
	nearby_terminal = term
	interact_prompt_changed.emit(term != null, "SINCRONIZAR RELÉ DE DADOS" if term else "")
func fire_energy_pulse() -> void:
	if fire_cooldown > 0.0 or is_recharging: return
	if energy_ammo <= 0: recharge_energy_cell(); return
	fire_cooldown = 0.16; energy_ammo -= 1; muzzle_flash.light_energy = 3.2; marker_mount.position.z += 0.045
	AudioManager.play_sfx("pulse", 0.06); stats_changed.emit(shield, energy_ammo, max_energy_ammo)
	pulse_ray.force_raycast_update()
	if pulse_ray.is_colliding():
		var col := pulse_ray.get_collider()
		if col and col.has_method("apply_energy_mark") and col.get("team") != team:
			col.apply_energy_mark(28.0, team, true); hit_marker_triggered.emit()
	if energy_ammo == 0: recharge_energy_cell()
func recharge_energy_cell() -> void:
	if is_recharging: return
	is_recharging = true; AudioManager.play_sfx("click")
	await get_tree().create_timer(1.1).timeout
	energy_ammo = max_energy_ammo; is_recharging = false; stats_changed.emit(shield, energy_ammo, max_energy_ammo)
func apply_energy_mark(amount: float, attacker_team: String, _is_player: bool = false) -> void:
	if attacker_team == team or not GameManager.is_match_active: return
	shield -= amount; damage_flash_triggered.emit(); stats_changed.emit(maxf(0.0, shield), energy_ammo, max_energy_ammo)
	if shield <= 0.0:
		GameManager.player_tagged_count += 1; GameManager.register_tag(attacker_team, false)
		shield = max_shield; global_position = spawn_point; stats_changed.emit(shield, energy_ammo, max_energy_ammo)
