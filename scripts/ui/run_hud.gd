extends Control


func update_state(state, act_title := "") -> void:
	get_node("Margin/Rows/ActRow/Act").text = act_title if not act_title.is_empty() else str(state.act_id).to_upper()
	get_node("Margin/Rows/ActRow/Score").text = "SCORE %06d" % state.score
	get_node("Margin/Rows/StateRow/Health").text = "♥ ".repeat(state.health).strip_edges()
	get_node("Margin/Rows/StateRow/Combo").text = "COMBO ×%d" % state.combo
	var species: Array[String] = ["DUCK"]
	for companion in state.companions:
		species.append(str(companion.species).to_upper())
	get_node("Margin/Rows/StateRow/Flock").text = " · ".join(species)
