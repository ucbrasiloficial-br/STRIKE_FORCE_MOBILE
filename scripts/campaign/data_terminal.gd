extends Area3D
@export var node_code: String = "RELÉ-01"
var is_hacked: bool = false
@onready var status_light: OmniLight3D = $StatusLight
func _ready() -> void:
	body_entered.connect(func(b): if not is_hacked and b.has_method("set_nearby_terminal"): b.set_nearby_terminal(self))
	body_exited.connect(func(b): if b.has_method("set_nearby_terminal"): b.set_nearby_terminal(null))
	if GameManager.current_mode != GameManager.GameMode.CAMPAIGN: visible = false; monitoring = false
func activate_terminal() -> void:
	if is_hacked or GameManager.current_mode != GameManager.GameMode.CAMPAIGN: return
	is_hacked = true; status_light.light_color = Color(0.05, 0.95, 0.55)
	AudioManager.play_sfx("marked"); GameManager.register_terminal_hacked()
