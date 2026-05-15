static func apply_janky_panel_theme(panels: Array[Control], ui_rng: RandomNumberGenerator) -> void:
	for panel_node in panels:
		if panel_node is PanelContainer:
			var panel: PanelContainer = panel_node as PanelContainer
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = Color(0.039 + ui_rng.randf_range(-0.01, 0.015), 0.078 + ui_rng.randf_range(-0.015, 0.020), 0.039 + ui_rng.randf_range(-0.01, 0.015))
			sb.border_width_left = 2 + ui_rng.randi_range(0, 1)
			sb.border_width_top = 3
			sb.border_width_right = 2 + ui_rng.randi_range(0, 1)
			sb.border_width_bottom = 3
			sb.border_color = Color(0.133 + ui_rng.randf_range(-0.04, 0.05), 0.510 + ui_rng.randf_range(-0.05, 0.06), 0.133 + ui_rng.randf_range(-0.04, 0.05))
			sb.corner_radius_top_left = 3 + ui_rng.randi_range(0, 2)
			sb.corner_radius_top_right = 2 + ui_rng.randi_range(0, 3)
			sb.corner_radius_bottom_left = 3 + ui_rng.randi_range(0, 2)
			sb.corner_radius_bottom_right = 2 + ui_rng.randi_range(0, 3)
			panel.add_theme_stylebox_override("panel", sb)
