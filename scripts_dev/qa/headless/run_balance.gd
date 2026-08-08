extends SceneTree

const RunSimulator = preload("res://scripts/core/simulation/run_simulator.gd")


func _init() -> void:
	var run_count := _runs_arg(10000)
	var report: Dictionary = RunSimulator.balance_report(run_count)
	assert(report.run_count == run_count, "report count matches the request")
	assert(_floor_reach_is_valid(report.floor_reach, run_count), "floor reach is complete and monotonic")
	assert(report.challenge_successes.keys().size() == 3, "all challenges are aggregated")
	assert(report.quirk_selections.keys().size() == 4, "all Quirks are aggregated")
	assert(not report.combo_histogram.is_empty(), "combo histogram is present")
	assert(report.completion_rates.has_all(["unboosted", "ad", "paid"]), "all Boost modes have completion rates")
	assert(report.impossible_states == 0, "no impossible state")
	assert(report.boost_parity_mismatches == 0, "same-seed ad and paid runs match")
	assert(report.boost_gameplay.ad == report.boost_gameplay.paid, "ad and paid aggregates are identical")

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_output"))
	var output := FileAccess.open("res://qa_output/headless_balance.json", FileAccess.WRITE)
	assert(output != null, "balance report output opens")
	output.store_string(JSON.stringify(report, "  "))
	print("PASS run_balance runs=%d completion=%s" % [run_count, JSON.stringify(report.completion_rates)])
	quit(0)


func _runs_arg(default_count: int) -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--runs="):
			return maxi(1, int(argument.trim_prefix("--runs=")))
	return default_count


func _floor_reach_is_valid(reach: Dictionary, run_count: int) -> bool:
	var previous := run_count
	for floor_number in range(1, 16):
		var count := int(reach.get(str(floor_number), -1))
		if count < 0 or count > previous:
			return false
		previous = count
	return true
