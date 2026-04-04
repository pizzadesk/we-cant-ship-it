static func update_ship_button_danger(ship_button: Button, runway_days: int, initial_runway_days: int) -> void:
	var danger_ratio: float = clampf(1.0 - (float(runway_days) / float(initial_runway_days)), 0.0, 1.0)
	var button_color: Color = Color(0.24, 0.21, 0.24).lerp(Color(0.95, 0.11, 0.07), danger_ratio)

	var normal_style: StyleBoxFlat = StyleBoxFlat.new()
	normal_style.bg_color = button_color
	normal_style.border_width_left = 3
	normal_style.border_width_top = 3
	normal_style.border_width_right = 3
	normal_style.border_width_bottom = 3
	normal_style.border_color = Color(1.0, 0.56, 0.50).lerp(Color(1.0, 0.15, 0.15), danger_ratio)
	normal_style.corner_radius_top_left = 4
	normal_style.corner_radius_top_right = 5
	normal_style.corner_radius_bottom_left = 5
	normal_style.corner_radius_bottom_right = 4
	normal_style.shadow_size = int(4 + (danger_ratio * 18.0))
	normal_style.shadow_color = Color(1.0, 0.07, 0.07, 0.22 + (danger_ratio * 0.55))

	var hover_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = button_color.lightened(0.12)

	var pressed_style: StyleBoxFlat = normal_style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = button_color.darkened(0.12)

	ship_button.add_theme_stylebox_override("normal", normal_style)
	ship_button.add_theme_stylebox_override("hover", hover_style)
	ship_button.add_theme_stylebox_override("pressed", pressed_style)
	ship_button.add_theme_color_override("font_color", Color(1.0, 0.95, 0.92))

static func next_glitch_offset(current_offset: Vector2, instability_visual: float, delta: float, ui_rng: RandomNumberGenerator, ceiling_pressure: float = 0.0) -> Vector2:
	var glitch_offset: Vector2 = current_offset
	if instability_visual > 0.28 or ceiling_pressure > 0.15:
		var t: float = (instability_visual - 0.28) / 0.72
		# ceiling_pressure tightens the glitch interval near the archetype ceiling, making
		# near-bust Shooter runs visually more frantic than equally-chaotic RPG runs.
		# Increase the 0.6 multiplier to widen the ceiling pressure effect on glitch rate.
		var chance_range: int = int(lerp(140.0, 22.0, clampf(t + ceiling_pressure * 0.6, 0.0, 1.0)))
		if ui_rng.randi_range(0, chance_range) == 0:
			var mag: float = lerp(1.8, 7.5, clampf(t + ceiling_pressure * 0.4, 0.0, 1.0))
			glitch_offset = Vector2(ui_rng.randf_range(-mag, mag), ui_rng.randf_range(-mag * 0.6, mag * 0.6))
	return glitch_offset.lerp(Vector2.ZERO, min(1.0, delta * 11.0))

static func compute_wobble_position(jank_time: float, instability_visual: float, glitch_offset: Vector2, wobble_clamp: float, ceiling_pressure: float = 0.0) -> Vector2:
	# Base amplitude scales with instability² for a sharp ramp-up in chaos feel.
	# ceiling_pressure adds archetype-specific urgency: the same raw Instability feels
	# more severe on a Shooter run (ceiling 42) than an RPG run (ceiling 55) because
	# the player is proportionally closer to busting the Defining Game window.
	# Increase the 1.5 multiplier to make the near-ceiling amplification more aggressive.
	var amp: float = instability_visual * instability_visual * 7.0 * (1.0 + ceiling_pressure * 1.5)
	var wobble: Vector2 = Vector2(
		sin(jank_time * 2.5) * amp,
		cos(jank_time * 1.7) * amp * 0.62
	)
	var raw_offset: Vector2 = wobble + glitch_offset
	return raw_offset.clamp(
		Vector2(-wobble_clamp, -wobble_clamp),
		Vector2(wobble_clamp, wobble_clamp)
	)

static func compute_wobble_modulate(instability_visual: float) -> Color:
	var polish_visual: float = 1.0 - instability_visual
	return Color(
		0.88 + (polish_visual * 0.12),
		0.88 + (polish_visual * 0.12),
		0.88 + (polish_visual * 0.07)
	).lerp(Color(1.0, 0.88, 0.84), instability_visual * 0.55)

static func compute_jank_tint_color(instability_visual: float) -> Color:
	var polish_visual: float = 1.0 - instability_visual
	return Color(0.18, 0.62, 0.28, 0.02 + (polish_visual * 0.08)).lerp(
		Color(0.88, 0.12, 0.10, 0.04 + (instability_visual * 0.22)),
		instability_visual
	)

static func should_show_scanline(instability_visual: float) -> bool:
	return instability_visual > 0.45

static func compute_scanline_opacity(instability_visual: float) -> float:
	return 0.02 + (instability_visual * 0.22)

static func compute_scanline_speed(instability_visual: float) -> float:
	return 1.5 + (instability_visual * instability_visual * 9.0)

static func compute_scanline_density(instability_visual: float) -> float:
	return 380.0 - (instability_visual * instability_visual * 270.0)

static func step_text_corruption_timer(current_timer: float, delta: float, instability_visual: float) -> Dictionary:
	if instability_visual >= 0.65:
		var t: float = (instability_visual - 0.65) / 0.35
		var next_timer: float = current_timer - delta
		if next_timer <= 0.0:
			var interval: float = lerp(2.8, 0.25, t)
			return {
				"timer": interval,
				"apply_corruption": true,
				"restore_text": false,
			}
		return {
			"timer": next_timer,
			"apply_corruption": false,
			"restore_text": false,
		}

	return {
		"timer": current_timer,
		"apply_corruption": false,
		"restore_text": true,
	}

static func apply_ui_corruption(corruptible_controls: Array[Control], base_control_text: Dictionary, ui_rng: RandomNumberGenerator, instability_visual: float) -> void:
	for control in corruptible_controls:
		var base_text: String = String(base_control_text.get(control, ""))
		var corrupted_text: String = corrupt_text(base_text, ui_rng, instability_visual)
		if control is Label:
			(control as Label).text = corrupted_text
		elif control is Button:
			(control as Button).text = corrupted_text

static func restore_ui_texts(corruptible_controls: Array[Control], base_control_text: Dictionary) -> void:
	for control in corruptible_controls:
		var base_text: String = String(base_control_text.get(control, ""))
		if control is Label:
			(control as Label).text = base_text
		elif control is Button:
			(control as Button).text = base_text

static func corrupt_text(base_text: String, ui_rng: RandomNumberGenerator, instability_visual: float) -> String:
	if base_text.is_empty():
		return base_text
	var swaps: int = 0
	if instability_visual >= 0.72 and base_text.length() > 10:
		swaps = 2
	elif instability_visual >= 0.38 and base_text.length() > 6:
		swaps = 1
	if swaps == 0:
		return base_text

	var chars: Array[String] = []
	for index in range(base_text.length()):
		chars.append(base_text.substr(index, 1))
	var min_index: int = 0 if chars.size() <= 2 else 1
	var max_index: int = chars.size() - 1 if chars.size() <= 2 else chars.size() - 2
	var replacements: PackedStringArray = PackedStringArray(["#", "?", "*"])
	for _swap_index in range(swaps):
		for _attempt in range(6):
			var char_index: int = ui_rng.randi_range(min_index, max_index)
			if chars[char_index] == " ":
				continue
			chars[char_index] = replacements[ui_rng.randi_range(0, replacements.size() - 1)]
			break
	return "".join(PackedStringArray(chars))
