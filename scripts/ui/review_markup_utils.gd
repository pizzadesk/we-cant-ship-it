static func normalize_review_markup(raw_text: String) -> String:
	# Reviews are data-driven; normalize accidental HTML-like tags to Godot BBCode.
	var text: String = raw_text
	text = text.replace("<br>", "\n")
	text = text.replace("<br/>", "\n")
	text = text.replace("<br />", "\n")
	text = text.replace("<b>", "[b]")
	text = text.replace("</b>", "[/b]")
	text = text.replace("<strong>", "[b]")
	text = text.replace("</strong>", "[/b]")
	text = text.replace("<i>", "[i]")
	text = text.replace("</i>", "[/i]")
	text = text.replace("<em>", "[i]")
	text = text.replace("</em>", "[/i]")
	text = text.replace("<u>", "[u]")
	text = text.replace("</u>", "[/u]")

	var tag_regex: RegEx = RegEx.new()
	if tag_regex.compile("<[^>]+>") == OK:
		text = tag_regex.sub(text, "", true)
	return text
