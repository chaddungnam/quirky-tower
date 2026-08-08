extends SceneTree

const TrialScene = preload("res://scenes/game/challenges/tower_trial.tscn")
const AppTheme = preload("res://ui/themes/app_theme.tres")

const EXPECTED_SCENES := {
	"timing_ring": "TimingRing",
	"tap_panic": "TapPanic",
	"drag_dodge": "DragDodge",
}


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for challenge_id: String in EXPECTED_SCENES:
		var trial := TrialScene.instantiate()
		trial.theme = AppTheme
		root.add_child(trial)
		trial.setup(0.4, {}, challenge_id)
		trial.begin()

		assert(trial.get("_phase") == "preview", "every floor opens with a short preview")
		assert(trial.get_node_or_null("IntroLayer") != null, "floor preview has a transition layer")
		assert(trial.get_node_or_null("MascotGuide") != null, "the host guides every floor")
		assert(trial.get_node_or_null("RoutePanel") == null, "the repeated route wall is removed")

		trial.call("_process", 0.8)
		assert(trial.get("_phase") == "active", "preview enters play without a continue button")
		var slot := trial.get_node("ChallengeSlot")
		assert(slot.get_child_count() == 1, "one microgame is active")
		assert(
			slot.get_child(0).name == EXPECTED_SCENES[challenge_id],
			"%s starts its own gameplay scene" % challenge_id
		)
		assert(trial.has_method("show_resolution"), "the floor owns its animated result beat")
		assert(trial.has_signal("resolution_finished"), "result beat advances automatically")
		trial.free()

	print("PASS tower_trial_test")
	quit(0)
