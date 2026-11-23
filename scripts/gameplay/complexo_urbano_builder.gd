extends Node3D
const PLAYER_SCENE := preload("res://scenes/characters/fps_player.tscn")
const BOT_SCENE := preload("res://scenes/characters/tactical_bot.tscn")
const HUD_SCENE := preload("res://scenes/gameplay/touch_hud.tscn")
const CRATE_GLB := preload("res://assets/props/tactical_crate.glb")
const TERMINAL_GLB := preload("res://assets/props/data_terminal.glb")
const TREE_GLB := preload("res://assets/props/urban_tree.glb")
const TERMINAL_SCRIPT := preload("res://scripts/campaign/data_terminal.gd")

func _ready() -> void:
	AudioManager.play_music("campaign")
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_SKY
	var sky := Sky.new(); var sm := ProceduralSkyMaterial.new()
	sm.sky_top_color = Color(0.06, 0.08, 0.16); sm.sky_horizon_color = Color(0.16, 0.22, 0.36); sm.ground_bottom_color = Color(0.04, 0.05, 0.08)
	sky.sky_material = sm; env.sky = sky; env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.75; env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env; add_child(we)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-48, 32, 0); sun.light_energy = 1.65; sun.shadow_enabled = true; add_child(sun)

	var mat_asphalt := _pbr("res://assets/textures/asphalt_albedo.png", "res://assets/textures/asphalt_normal.png", Vector3(24,24,1), 0.05, 0.88)
	var mat_concrete := _pbr("res://assets/textures/concrete_albedo.png", "res://assets/textures/concrete_normal.png", Vector3(6,4,1), 0.1, 0.75)
	var mat_metal := _pbr("res://assets/textures/tactical_metal_albedo.png", "res://assets/textures/tactical_metal_normal.png", Vector3(4,3,1), 0.7, 0.35)

	_box(Vector3(0,-0.5,0), Vector3(90,1,90), mat_asphalt)
	_box(Vector3(0,3,-45), Vector3(90,6,1.2), mat_concrete); _box(Vector3(0,3,45), Vector3(90,6,1.2), mat_concrete)
	_box(Vector3(-45,3,0), Vector3(1.2,6,90), mat_concrete); _box(Vector3(45,3,0), Vector3(1.2,6,90), mat_concrete)
	_box(Vector3(-16,4,-18), Vector3(14,8,1), mat_concrete); _box(Vector3(-23,4,-11), Vector3(1,8,14), mat_concrete); _box(Vector3(-9,4,-11), Vector3(1,8,14), mat_concrete)
	_box(Vector3(-19.5,4,-4), Vector3(6,8,1), mat_concrete); _box(Vector3(-11.5,4,-4), Vector3(4,8,1), mat_concrete); _box(Vector3(-16,8.2,-11), Vector3(15,0.6,15), mat_metal)
	_box(Vector3(20,4.5,-10), Vector3(14,9,16), mat_concrete); _box(Vector3(13,2.2,-10), Vector3(0.8,4.4,16), mat_metal)
	_box(Vector3(-18,3.5,18), Vector3(14,7,12), mat_concrete); _box(Vector3(18,3.5,18), Vector3(14,7,12), mat_concrete); _box(Vector3(0,1.2,0), Vector3(8,2.4,3), mat_metal)

	for p in [Vector3(-4,0,6), Vector3(5,0,-5), Vector3(-15,0,-10), Vector3(11,0,8), Vector3(-10,0,15), Vector3(12,0,-22)]:
		var c := CRATE_GLB.instantiate(); c.position = p; add_child(c)
		_col_only(p + Vector3(0, 0.475, 0), Vector3(1.35, 0.95, 0.95))
	for tp in [Vector3(-28,0,-26), Vector3(28,0,-28), Vector3(-30,0,26), Vector3(30,0,24)]:
		var t := TREE_GLB.instantiate(); t.position = tp; add_child(t)
	for item in [{"code":"RELÉ-01","pos":Vector3(-16,0,-12)}, {"code":"RELÉ-02","pos":Vector3(10,0,-10)}, {"code":"RELÉ-03","pos":Vector3(0,0,-26)}]:
		var a := Area3D.new(); a.set_script(TERMINAL_SCRIPT); a.node_code = item["code"]; a.position = item["pos"]
		a.add_child(TERMINAL_GLB.instantiate())
		var cs := CollisionShape3D.new(); var sp := SphereShape3D.new(); sp.radius = 2.4; cs.shape = sp; a.add_child(cs)
		var l := OmniLight3D.new(); l.name = "StatusLight"; l.position = Vector3(0,1.4,0.4); l.light_color = Color(0.1,0.78,1); l.light_energy = 2.2; a.add_child(l)
		add_child(a)

	var pl := PLAYER_SCENE.instantiate(); pl.position = Vector3(0, 0.2, 26); add_child(pl)
	for pos in [Vector3(-6,0.2,24), Vector3(6,0.2,24)]:
		var b := BOT_SCENE.instantiate(); b.team = "ALPHA"; b.position = pos; add_child(b)
	for pos in [Vector3(-12,0.2,-24), Vector3(0,0.2,-28), Vector3(14,0.2,-22)]:
		var b := BOT_SCENE.instantiate(); b.team = "OMEGA"; b.position = pos; add_child(b)
	add_child(HUD_SCENE.instantiate())

func _pbr(a: String, n: String, uv: Vector3, met: float, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_texture = load(a); m.normal_enabled = true; m.normal_texture = load(n); m.uv1_scale = uv; m.metallic = met; m.roughness = rough; return m
func _box(pos: Vector3, sz: Vector3, mat: Material) -> void:
	var b := StaticBody3D.new(); b.position = pos; var mi := MeshInstance3D.new(); var bx := BoxMesh.new(); bx.size = sz; bx.material = mat; mi.mesh = bx; b.add_child(mi)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = sz; cs.shape = sh; b.add_child(cs); add_child(b)
func _col_only(pos: Vector3, sz: Vector3) -> void:
	var b := StaticBody3D.new(); b.position = pos; var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = sz; cs.shape = sh; b.add_child(cs); add_child(b)
