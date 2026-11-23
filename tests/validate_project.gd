extends SceneTree
func _init() -> void:
	for path in [
		"res://scenes/menus/main_menu.tscn", "res://scenes/menus/results_screen.tscn",
		"res://scenes/maps/complexo_urbano.tscn", "res://scenes/characters/fps_player.tscn",
		"res://scenes/characters/tactical_bot.tscn", "res://scenes/gameplay/touch_hud.tscn",
		"res://assets/characters/operative_vanguard_m.glb", "res://assets/characters/operative_spectre_f.glb",
		"res://assets/characters/operative_phantom_rival.glb", "res://assets/equipment/pulse_marker_vx1.glb"
	]:
		if load(path) == null:
			push_error("FALHA DE VALIDAÇÃO: " + path); quit(1); return
	print("VALIDAÇÃO STRIKE FORCE MOBILE OK.")
	quit(0)
