extends Control


func update_state(state) -> void:
	get_node("Margin/Row/Floor").text = "%dF" % state.floor
	get_node("Margin/Row/Score").text = "%06d" % state.score
	get_node("Margin/Row/Combo").text = "COMBO ×%d" % state.combo
	get_node("Margin/Row/Hearts").text = "♥ ".repeat(state.hearts).strip_edges()
