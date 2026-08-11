extends SceneTree

const MAIN_SCENE := preload("res://scenes/app/main.tscn")
const CAPTURE_SIZE := Vector2i(1080, 2400)
const LOGICAL_SIZE := Vector2i(720, 1600)
const SEED := 424242
const FINGER_OFFSET := Vector2(0.0, 160.0)

var _output_dir := ""
var _viewport: SubViewport
var _app: Control
var _world: FlockWorld3D
var _last_collapse_stage := ""
var _last_impact := ""
var _pause_rescue := false
var _pause_rebound := false
var _pause_collapse := false
var _pause_strike := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_output_dir = _argument_value("--output-dir")
	if _output_dir.is_empty() or not DirAccess.dir_exists_absolute(_output_dir):
		_fail("--output-dir must name an existing directory")
		return
	TranslationServer.set_locale("ko")
	_viewport = SubViewport.new()
	_viewport.name = "GateACaptureViewport"
	_viewport.size = CAPTURE_SIZE
	_viewport.size_2d_override = LOGICAL_SIZE
	_viewport.size_2d_override_stretch = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_app = MAIN_SCENE.instantiate() as Control
	_viewport.add_child(_app)
	await process_frame
	await create_timer(0.25).timeout
	await _capture("boot")

	_app.get_node("SplashScreen").finish_now()
	_app.select_language("ko")
	_app.show_run()
	var run_screen := _app.get_node("RunScreen") as Control
	run_screen.restart_run(SEED)
	await process_frame
	await process_frame
	var safe_frame := run_screen.get_node("SafeFrame") as Control
	if safe_frame.position != Vector2(0.0, 160.0) or safe_frame.size != Vector2(720.0, 1280.0):
		_fail("centered 720x1280 safe frame is missing")
		return
	var trial := run_screen.get_node("ChallengeSlot/FlockTrial") as FlockTrial
	_world = trial.get_node("FlockWorld3D") as FlockWorld3D
	_world.collapse_stage.connect(_on_collapse_stage)
	_world.impact.connect(_on_impact)

	var camera := _world.get_node("Camera") as Camera3D
	var leader := _world.get_node("Actors/Leader") as CharacterBody3D
	var rescue := _world.get_node("Encounter/Rescue") as Area3D
	var touch_position := camera.unproject_position(leader.global_position) + FINGER_OFFSET
	_push_touch(true, touch_position)
	await process_frame
	var approach_position := rescue.global_position + Vector3(0.0, 0.0, 2.2)
	_push_drag(touch_position, camera.unproject_position(approach_position) + FINGER_OFFSET)
	await _wait_physics_frames(28)
	_pause_rescue = true
	_push_drag(
		camera.unproject_position(approach_position) + FINGER_OFFSET,
		camera.unproject_position(rescue.global_position) + FINGER_OFFSET
	)
	if not await _wait_for_impact("rescue", 180):
		return
	if str(trial.get_visual_state().act_id) != "entry":
		_fail("rescue beat advanced before the entry capture")
		return
	await _capture("entry")
	paused = false
	_pause_rescue = false
	if not await _wait_for_act(trial, "brawl", 180):
		_fail("real entry drag did not reach the rescue route")
		return
	await create_timer(0.35).timeout
	await _capture("brawl_warning")

	_pause_collapse = true
	_pause_rebound = true
	for _attempt in range(4):
		if _last_collapse_stage == "contact":
			break
		await _dash_toward_weak_point()
		await create_timer(0.30).timeout
	if _last_collapse_stage != "contact":
		_fail("real brawl swipes did not contact the weak point")
		return
	await _capture("brawl_contact")
	paused = false
	if not await _wait_for_impact("rebound", 120):
		return
	await _capture("brawl_rebound")
	paused = false
	_pause_rebound = false
	if not await _wait_for_collapse_stage("crack", 120):
		return
	await _capture("collapse_crack")
	paused = false
	if not await _wait_for_collapse_stage("pieces", 120):
		return
	await _capture("collapse_pieces")
	paused = false
	if not await _wait_for_collapse_stage("collapse", 120):
		return
	await _capture("collapse_target")
	paused = false
	if not await _wait_for_collapse_stage("reward", 120):
		return
	if str(trial.get_visual_state().act_id) != "brawl":
		_fail("collapse reward capture is not visibly owned by Brawl")
		return
	var hud_act := run_screen.get_node("SafeFrame/RunHud/Margin/Rows/ActRow/Act") as Label
	if not hud_act.text.begins_with("2막"):
		_fail("collapse reward HUD advanced before the Brawl reward capture")
		return
	await _capture("collapse_reward")
	paused = false
	_pause_collapse = false
	if not await _wait_for_act(trial, "chain", 120):
		_fail("Brawl reward did not advance to Chain")
		return
	await create_timer(0.30).timeout

	var targets: Dictionary = _world.get("_chain_targets")
	var first_target := targets["antenna_a"] as Node3D
	var second_target := targets["relay_b"] as Node3D
	var third_target := targets["vent_c"] as Node3D
	var first_screen := camera.unproject_position(first_target.global_position)
	_push_touch(true, first_screen)
	await process_frame
	_push_touch(false, first_screen)
	await create_timer(0.18).timeout
	await _capture("chain_broken")

	_push_touch(true, first_screen)
	await process_frame
	_push_drag(first_screen, camera.unproject_position(second_target.global_position))
	await process_frame
	_push_drag(camera.unproject_position(second_target.global_position), camera.unproject_position(third_target.global_position))
	await process_frame
	await _capture("chain_path")
	_pause_strike = true
	_push_touch(false, camera.unproject_position(third_target.global_position))
	if not await _wait_for_impact("chain_strike", 180):
		return
	await _capture("chain_strike")
	paused = false
	_pause_strike = false
	if not await _wait_for_act(trial, "choice", 240):
		_fail("real chain release did not finish the district")
		return
	await create_timer(0.35).timeout
	await _capture("choice")

	var actions := run_screen.get_node("SafeFrame/GameOverlay/Center/Card/Content/ActionScroll/Actions") as VBoxContainer
	if actions.get_child_count() != 3:
		_fail("choice overlay does not have exactly three actions")
		return
	var choice_button := actions.get_child(0) as Button
	var choice_position := choice_button.get_global_rect().get_center()
	_push_touch(true, choice_position)
	await process_frame
	_push_touch(false, choice_position)
	if not await _wait_for_act(trial, "complete", 120):
		_fail("real choice touch did not apply the build")
		return
	await create_timer(0.35).timeout
	await _capture("result")

	print("GATE_A_GODOT_VERSION=%s" % Engine.get_version_info().string)
	print("GATE_A_RENDERER=macOS Metal, %s, %s" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name()])
	print("PASS capture_gate_a")
	quit(0)


func _argument_value(key: String) -> String:
	var arguments := OS.get_cmdline_user_args()
	for index in range(arguments.size() - 1):
		if arguments[index] == key:
			return arguments[index + 1]
	return ""


func _capture(state: String) -> void:
	await RenderingServer.frame_post_draw
	var image := _viewport.get_texture().get_image()
	if image.get_size() != CAPTURE_SIZE:
		_fail("%s capture size is %s" % [state, image.get_size()])
		return
	var error := image.save_png(_output_dir.path_join("%s.png" % state))
	if error != OK:
		_fail("%s capture could not be saved: %s" % [state, error_string(error)])


func _dash_toward_weak_point() -> void:
	var leader := _world.get_node("Actors/Leader") as CharacterBody3D
	var weak_point := _world.get_node("Encounter/BrawlWeakPoint") as RigidBody3D
	var world_direction := weak_point.global_position - leader.global_position
	var screen_direction := Vector2(world_direction.x, world_direction.z).normalized()
	var start := Vector2(360.0, 800.0) - screen_direction * 140.0
	var finish := Vector2(360.0, 800.0) + screen_direction * 140.0
	_push_touch(true, start)
	await process_frame
	_push_drag(start, finish)
	await process_frame
	_push_touch(false, finish)


func _push_touch(pressed: bool, position: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = position
	event.pressed = pressed
	_viewport.push_input(event, true)


func _push_drag(previous: Vector2, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 0
	event.position = position
	event.relative = position - previous
	event.velocity = event.relative * 60.0
	_viewport.push_input(event, true)


func _wait_physics_frames(count: int) -> void:
	for _frame in range(count):
		await physics_frame


func _wait_for_act(trial: FlockTrial, act_id: String, frame_limit: int) -> bool:
	for _frame in range(frame_limit):
		if str(trial.get_visual_state().act_id) == act_id:
			return true
		await process_frame
	return false


func _wait_for_collapse_stage(stage: String, frame_limit: int) -> bool:
	for _frame in range(frame_limit):
		if _last_collapse_stage == stage:
			return true
		await process_frame
	_fail("collapse stage did not reach %s" % stage)
	return false


func _wait_for_impact(kind: String, frame_limit: int) -> bool:
	for _frame in range(frame_limit):
		if _last_impact == kind:
			return true
		await physics_frame
		await process_frame
	_fail("impact did not reach %s" % kind)
	return false


func _on_collapse_stage(stage: String) -> void:
	_last_collapse_stage = stage
	if _pause_collapse and stage in ["contact", "crack", "pieces", "collapse", "reward"]:
		paused = true


func _on_impact(kind: String, _world_point: Vector3) -> void:
	_last_impact = kind
	if (
		(_pause_rescue and kind == "rescue")
		or (_pause_rebound and kind == "rebound")
		or (_pause_strike and kind == "chain_strike")
	):
		paused = true


func _fail(message: String) -> void:
	paused = false
	push_error(message)
	quit(1)
