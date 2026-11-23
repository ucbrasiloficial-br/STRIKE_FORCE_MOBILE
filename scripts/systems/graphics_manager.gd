extends Node
enum Quality { BAIXA = 0, MEDIA = 1, ALTA = 2, ULTRA = 3 }
func apply_quality(preset: int) -> void:
	preset = clampi(preset, 0, 3)
	SaveSystem.data["settings"]["quality_preset"] = preset
	SaveSystem.save_game()
	var vp := get_viewport()
	if not vp: return
	match preset:
		Quality.BAIXA: vp.scaling_3d_scale = 0.65; vp.msaa_3d = Viewport.MSAA_DISABLED; RenderingServer.directional_shadow_atlas_set_size(1024, true)
		Quality.MEDIA: vp.scaling_3d_scale = 0.80; vp.msaa_3d = Viewport.MSAA_DISABLED; RenderingServer.directional_shadow_atlas_set_size(2048, true)
		Quality.ALTA: vp.scaling_3d_scale = 0.95; vp.msaa_3d = Viewport.MSAA_2X; RenderingServer.directional_shadow_atlas_set_size(3072, true)
		Quality.ULTRA: vp.scaling_3d_scale = 1.0; vp.msaa_3d = Viewport.MSAA_4X; RenderingServer.directional_shadow_atlas_set_size(4096, true)
func get_render_distance() -> float:
	match int(SaveSystem.data["settings"]["quality_preset"]):
		0: return 75.0
		1: return 110.0
		2: return 160.0
		_: return 240.0
