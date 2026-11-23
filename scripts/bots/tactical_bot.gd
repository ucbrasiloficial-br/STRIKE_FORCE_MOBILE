extends CharacterBody3D
@export var team: String = "OMEGA"
@export var move_speed: float = 4.6
@export var max_shield: float = 100.0
var shield: float = 100.0
var spawn_origin: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var fire_timer: float = 0.0
var decision_timer: float = 0.0
var anim_player: AnimationPlayer = null
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var model_holder: Node3D = $ModelHolder
@onready var los_ray: RayCast3D = $LineOfSightRay

func _ready() -> void:
	add_to_group("combatants"); add_to_group("team_" + team.to_lower())
	spawn_origin = global_position; patrol_target = spawn_origin
	match GameManager.current_difficulty:
		0: move_speed = 3.8
		1: move_speed = 4.7
		2: move_speed = 5.6
	_find_anim(model_holder); _play_anim("Idle")

func _find_anim(node: Node) -> void:
	for c in node.get_children():
		if c is AnimationPlayer: anim_player = c; return
		_find_anim(c)
func _play_anim(n: String) -> void:
	if anim_player and anim_player.has_animation(n) and anim_player.current_animation != n: anim_player.play(n)

func _physics_process(delta: float) -> void:
	if not GameManager.is_match_active: return
	if not is_on_floor(): velocity += get_gravity() * delta
	fire_timer = maxf(0.0, fire_timer - delta); decision_timer -= delta
	var target := _find_nearest_enemy()
	if target:
		var flat := Vector3(target.global_position.x, global_position.y, target.global_position.z)
		if global_position.distance_to(flat) > 0.5: look_at(flat, Vector3.UP)
		var dist := global_position.distance_to(target.global_position)
		if dist < 26.0 and _has_los(target):
			_shoot(target)
			if dist > 9.0: _move_to(target.global_position, true)
			else: velocity.x = 0.0; velocity.z = 0.0; _play_anim("Idle")
		else: _move_to(target.global_position, false)
	else:
		if decision_timer <= 0.0:
			decision_timer = randf_range(2.5, 4.5)
			patrol_target = spawn_origin + Vector3(randf_range(-16.0, 16.0), 0.0, randf_range(-16.0, 16.0))
		_move_to(patrol_target, false)
	move_and_slide()

func _move_to(dest: Vector3, sprint: bool) -> void:
	nav_agent.target_position = dest
	var nxt := nav_agent.get_next_path_position()
	if nxt.distance_to(global_position) < 0.25: nxt = dest
	var dir := nxt - global_position; dir.y = 0.0
	if dir.length() > 0.35:
		dir = dir.normalized()
		var spd := move_speed * (1.15 if sprint else 0.85)
		velocity.x = dir.x * spd; velocity.z = dir.z * spd
		look_at(global_position + dir, Vector3.UP)
		_play_anim("Run" if sprint else "Walk")
	else: velocity.x = 0.0; velocity.z = 0.0; _play_anim("Idle")

func _find_nearest_enemy() -> Node3D:
	var best: Node3D = null; var bd := 9999.0
	for c in get_tree().get_nodes_in_group("combatants"):
		if c != self and is_instance_valid(c) and c.get("team") != team:
			var d := global_position.distance_to(c.global_position)
			if d < bd: bd = d; best = c
	return best

func _has_los(t: Node3D) -> bool:
	los_ray.target_position = los_ray.to_local(t.global_position + Vector3(0, 1.2, 0))
	los_ray.force_raycast_update()
	return not los_ray.is_colliding() or los_ray.get_collider() == t

func _shoot(t: Node3D) -> void:
	if fire_timer > 0.0: return
	fire_timer = [1.15, 0.78, 0.55][GameManager.current_difficulty]
	if randf() <= [0.32, 0.52, 0.72][GameManager.current_difficulty] and t.has_method("apply_energy_mark"):
		t.apply_energy_mark(16.0, team, false)

func apply_energy_mark(amount: float, attacker_team: String, is_player: bool = false) -> void:
	if attacker_team == team or not GameManager.is_match_active: return
	shield -= amount
	if shield <= 0.0: GameManager.register_tag(attacker_team, is_player); shield = max_shield; global_position = spawn_origin
