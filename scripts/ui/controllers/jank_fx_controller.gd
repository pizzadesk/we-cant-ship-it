extends RefCounted
class_name JankFxController

const JankVisualUtils = preload("res://scripts/ui/jank_visual_utils.gd")
const SynergyToastUtils = preload("res://scripts/ui/synergy_toast_utils.gd")
const ThemeUtils = preload("res://scripts/ui/theme_utils.gd")

var _owner: Node = null
var _ui_rng: RandomNumberGenerator = null
var _scanline_shader: Shader = null
var _scanline_overlay: ColorRect = null
var _jank_tint: ColorRect = null
var _wobble_root: MarginContainer = null
var _ship_button: Button = null
var _scanline_material: ShaderMaterial = null
var _corruptible_controls: Array[Control] = []
var _base_control_text: Dictionary = {}
var _synergy_toast: PanelContainer = null
var _synergy_toast_timer: Timer = null
var _text_corruption_timer: float = 0.0
var _jank_time: float = 0.0
var _glitch_offset: Vector2 = Vector2.ZERO

func setup(
	owner: Node,
	ui_rng: RandomNumberGenerator,
	scanline_shader: Shader,
	scanline_overlay: ColorRect,
	jank_tint: ColorRect,
	wobble_root: MarginContainer,
	ship_button: Button,
) -> void:
	_owner = owner
	_ui_rng = ui_rng
	_scanline_shader = scanline_shader
	_scanline_overlay = scanline_overlay
	_jank_tint = jank_tint
	_wobble_root = wobble_root
	_ship_button = ship_button

	_scanline_material = ShaderMaterial.new()
	_scanline_material.shader = _scanline_shader
	_scanline_overlay.material = _scanline_material

func apply_janky_ui_theme(panels: Array[Control]) -> void:
	ThemeUtils.apply_janky_panel_theme(panels, _ui_rng)

func cache_corruptible_ui_text(controls: Array[Control]) -> void:
	_corruptible_controls = controls.duplicate()
	_base_control_text.clear()
	for control in _corruptible_controls:
		if control is Label:
			_base_control_text[control] = (control as Label).text
		elif control is Button:
			_base_control_text[control] = (control as Button).text

func process(delta: float, menu_active: bool, instability_visual: float, instability_ceiling_pressure: float, wobble_clamp: float) -> void:
	if menu_active:
		_wobble_root.position = Vector2.ZERO
		_wobble_root.modulate = Color(1.0, 1.0, 1.0)
		_jank_tint.visible = false
		_scanline_overlay.visible = false
		restore_ui_texts()
		return

	_jank_time += delta
	if instability_visual >= 0.25:
		_glitch_offset = JankVisualUtils.next_glitch_offset(_glitch_offset, instability_visual, delta, _ui_rng, instability_ceiling_pressure)
		_wobble_root.position = JankVisualUtils.compute_wobble_position(_jank_time, instability_visual, _glitch_offset, wobble_clamp, instability_ceiling_pressure)
		_wobble_root.modulate = JankVisualUtils.compute_wobble_modulate(instability_visual)
	else:
		_glitch_offset = Vector2.ZERO
		_wobble_root.position = Vector2.ZERO
		_wobble_root.modulate = Color.WHITE

	_jank_tint.visible = instability_visual >= 0.25
	if instability_visual >= 0.25:
		_jank_tint.color = JankVisualUtils.compute_jank_tint_color(instability_visual)

	_scanline_overlay.visible = instability_visual >= 0.45
	if instability_visual >= 0.45 and _scanline_material != null:
		_scanline_material.set_shader_parameter("opacity", JankVisualUtils.compute_scanline_opacity(instability_visual))
		_scanline_material.set_shader_parameter("speed", JankVisualUtils.compute_scanline_speed(instability_visual))
		_scanline_material.set_shader_parameter("density", JankVisualUtils.compute_scanline_density(instability_visual))

	var text_step: Dictionary = JankVisualUtils.step_text_corruption_timer(_text_corruption_timer, delta, instability_visual)
	_text_corruption_timer = float(text_step.get("timer", _text_corruption_timer))
	if bool(text_step.get("apply_corruption", false)):
		apply_ui_corruption(instability_visual)
	elif bool(text_step.get("restore_text", false)):
		restore_ui_texts()

func update_ship_button_danger(runway_days: int, initial_runway_days: int) -> void:
	JankVisualUtils.update_ship_button_danger(_ship_button, runway_days, initial_runway_days)

func setup_synergy_toast() -> void:
	_synergy_toast = SynergyToastUtils.setup_synergy_toast(_owner)

func show_synergy_toast(
	flavor: String,
	instability_delta: int,
	soul_delta: int,
	synergy_toast_duration: float,
	synergy_toast_fade_in: float,
	on_timeout: Callable,
) -> void:
	_synergy_toast_timer = SynergyToastUtils.show_synergy_toast(
		_owner,
		_synergy_toast,
		_synergy_toast_timer,
		flavor,
		instability_delta,
		soul_delta,
		synergy_toast_duration,
		synergy_toast_fade_in,
		on_timeout
	)

func fade_out_synergy_toast(synergy_toast_fade_out: float) -> Tween:
	return SynergyToastUtils.fade_out_synergy_toast(_owner, _synergy_toast, synergy_toast_fade_out)

func clear_synergy_toast_timer() -> void:
	if _synergy_toast_timer != null:
		_synergy_toast_timer.queue_free()
		_synergy_toast_timer = null

func hide_synergy_toast() -> void:
	if _synergy_toast != null:
		_synergy_toast.hide()

func apply_ui_corruption(instability_visual: float) -> void:
	JankVisualUtils.apply_ui_corruption(_corruptible_controls, _base_control_text, _ui_rng, instability_visual)

func restore_ui_texts() -> void:
	JankVisualUtils.restore_ui_texts(_corruptible_controls, _base_control_text)