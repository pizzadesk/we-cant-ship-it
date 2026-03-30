static func apply_janky_panel_theme(panels: Array[Node], ui_rng: RandomNumberGenerator) -> void:
	for panel_node in panels:
		if panel_node is PanelContainer:
			var panel: PanelContainer = panel_node as PanelContainer
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = Color(0.10 + ui_rng.randf_range(-0.02, 0.03), 0.10 + ui_rng.randf_range(-0.02, 0.03), 0.13 + ui_rng.randf_range(-0.02, 0.02))
			sb.border_width_left = 2 + ui_rng.randi_range(0, 1)
			sb.border_width_top = 3
			sb.border_width_right = 2 + ui_rng.randi_range(0, 1)
			sb.border_width_bottom = 3
			sb.border_color = Color(0.54 + ui_rng.randf_range(-0.08, 0.08), 0.64 + ui_rng.randf_range(-0.08, 0.08), 0.82 + ui_rng.randf_range(-0.08, 0.08))
			sb.corner_radius_top_left = 3 + ui_rng.randi_range(0, 2)
			sb.corner_radius_top_right = 2 + ui_rng.randi_range(0, 3)
			sb.corner_radius_bottom_left = 3 + ui_rng.randi_range(0, 2)
			sb.corner_radius_bottom_right = 2 + ui_rng.randi_range(0, 3)
			panel.add_theme_stylebox_override("panel", sb)
