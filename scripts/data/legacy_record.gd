extends Resource
class_name LegacyRecord

# A single studio legacy — the reputation crystallised from one shipped run.
# Stored in meta_progress; displayed in studio briefing; drives card unlock flavour.

@export var name: String = ""          # Generated phrase: "games where the horse wins"
@export var type: String = ""          # celebrated | notorious | regretted | disaster | sellout | cult_disaster
@export var tier: int = 1             # 1–4; set at the time this legacy is crystallised
@export var run_identity: String = "" # Run identity at ship time (Cult Jank / Community Darling etc.)
@export var review_score: float = 0.0
@export var era_label: String = ""    # Narrative era: "The Early Days", "The Long Middle", etc.

func to_dictionary() -> Dictionary:
	return {
		"name": name,
		"type": type,
		"tier": tier,
		"run_identity": run_identity,
		"review_score": review_score,
		"era_label": era_label,
	}

static func from_dictionary(d: Dictionary) -> LegacyRecord:
	var r: LegacyRecord = LegacyRecord.new()
	r.name = String(d.get("name", ""))
	r.type = String(d.get("type", ""))
	r.tier = int(d.get("tier", 1))
	r.run_identity = String(d.get("run_identity", ""))
	r.review_score = float(d.get("review_score", 0.0))
	r.era_label = String(d.get("era_label", ""))
	return r

func is_empty() -> bool:
	return name.is_empty()
