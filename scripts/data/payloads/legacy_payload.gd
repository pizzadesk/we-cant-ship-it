extends RefCounted
class_name LegacyPayload

@warning_ignore("shadowed_global_identifier")
const LegacyRecord = preload("res://scripts/data/legacy_record.gd")

# Signal payload emitted on GameEvents.legacy_resolved after each ship.
# Carries both the newly crystallised legacy and the current active one
# so UI can present the displacement choice without querying AppState directly.

var pending_legacy: LegacyRecord = null   # Just generated from this run
var active_legacy: LegacyRecord = null    # Previously held legacy (may be null on first run)
var legacy_tier: int = 1                  # Current tier after this run's tier update

static func build(pending: LegacyRecord, active: LegacyRecord, tier: int) -> LegacyPayload:
	var p: LegacyPayload = LegacyPayload.new()
	p.pending_legacy = pending
	p.active_legacy = active
	p.legacy_tier = tier
	return p
