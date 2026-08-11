class_name FlockTrial
extends Control

signal district_finished
signal state_changed(snapshot: Dictionary)

const MOUSE_POINTER_ID := -2
const ACT_COPY := {
	"ko": {
		"entry": ["1막 · 구출 진입", "끌어서 동료를 구해!"],
		"brawl": ["2막 · 옥상 난투", "짧게 그어 약점으로 날려!"],
		"chain": ["3막 · 사슬 습격", "약점을 잇고 손을 떼!"],
	},
	"en": {
		"entry": ["ACT 1 · RESCUE", "Drag to rescue your flock!"],
		"brawl": ["ACT 2 · ROOFTOP BRAWL", "Swipe them into the weak point!"],
		"chain": ["ACT 3 · CHAIN RAID", "Link weak points and release!"],
	},
}

var _run_state: FlockRunState
var _locale := "ko"
var _pointer_id := -1
var _press_position := Vector2.ZERO
var _press_time_usec := 0
var _mascot_line := ""

@onready var _world: FlockWorld3D = $FlockWorld3D
@onready var _mascot: Control = $SafeFrame/MascotGuide


func _ready() -> void:
	_world.act_completed.connect(_on_act_completed)
	_world.reward_released.connect(_on_reward_released)
	_world.flock_changed.connect(func(snapshot: Dictionary) -> void: state_changed.emit(snapshot))
	_world.impact.connect(_on_impact)


func begin(run_state: FlockRunState) -> void:
	_run_state = run_state
	_world.setup(run_state)
	_start_act("entry")


func set_language(locale: String) -> void:
	_locale = "ko" if locale.replace("-", "_").begins_with("ko") else "en"
	if _run_state != null and _run_state.act_id in ACT_COPY[_locale]:
		_apply_act_copy(_run_state.act_id)


func cancel_input() -> void:
	_pointer_id = -1
	_world.cancel_gesture()


func get_visual_state() -> Dictionary:
	return {
		"act_id": _run_state.act_id if _run_state != null else "",
		"act_title": _act_copy(0),
		"mascot_line": _mascot_line,
		"pointer_active": _pointer_id != -1,
		"pointer_id": _pointer_id,
		"run_state": _run_state,
	}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _pointer_id == -1:
			_start_pointer(event.index, event.position)
		elif not event.pressed and _pointer_id == event.index:
			_release_pointer(event.position)
	elif event is InputEventScreenDrag and _pointer_id == event.index:
		_world.set_drag_target(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _pointer_id == -1:
			_start_pointer(MOUSE_POINTER_ID, event.position)
		elif not event.pressed and _pointer_id == MOUSE_POINTER_ID:
			_release_pointer(event.position)
	elif event is InputEventMouseMotion and _pointer_id == MOUSE_POINTER_ID:
		_world.set_drag_target(event.position)


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		cancel_input()


func _start_pointer(pointer_id: int, position: Vector2) -> void:
	_pointer_id = pointer_id
	_press_position = position
	_press_time_usec = Time.get_ticks_usec()
	_world.set_drag_target(position)


func _release_pointer(position: Vector2) -> void:
	var elapsed := maxf((Time.get_ticks_usec() - _press_time_usec) / 1000000.0, 0.001)
	var velocity := (position - _press_position) / elapsed
	_pointer_id = -1
	_world.release_swipe(position, velocity)


func _start_act(act_id: String) -> void:
	cancel_input()
	_world.start_act(act_id)
	_apply_act_copy(act_id)
	state_changed.emit(_run_state.snapshot())


func _apply_act_copy(act_id: String) -> void:
	_mascot_line = str(ACT_COPY[_locale][act_id][1])
	_mascot.say(_mascot_line)


func _act_copy(index: int) -> String:
	if _run_state == null or _run_state.act_id not in ACT_COPY[_locale]:
		return ""
	return str(ACT_COPY[_locale][_run_state.act_id][index])


func _on_act_completed(act_id: String, _result: Dictionary) -> void:
	if _run_state == null:
		return
	if act_id == "entry" and _run_state.act_id == "entry":
		_start_act("brawl")
	elif act_id == "chain" and _run_state.act_id == "chain":
		cancel_input()
		_run_state.begin_act("choice")
		state_changed.emit(_run_state.snapshot())
		district_finished.emit()


func _on_reward_released(value: int) -> void:
	if _run_state == null:
		return
	_run_state.score += value * 100
	_run_state.combo += value
	state_changed.emit(_run_state.snapshot())
	if _run_state.act_id == "brawl":
		_start_act("chain")


func _on_impact(kind: String, _world_point: Vector3) -> void:
	_mascot.react("fail" if kind == "hazard" else "success")
