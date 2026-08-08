class_name SponsorBoost
extends RefCounted


static func apply(state, source: String) -> Dictionary:
	if source != "ad" and source != "paid":
		return {"ok": false, "reason": "invalid_source"}
	if state.boost_used:
		return {"ok": false, "reason": "run_limit"}
	state.hearts += 1
	state.boost_used = true
	state.boost_source = source
	return {"ok": true, "reason": ""}
