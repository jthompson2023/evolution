extends Area2D

export var do_nothing = true
var escape_vector := Vector2.ZERO


func _process(_delta):
	if not do_nothing:
		var cells = get_sensed()["cell"]
		escape_vector = Vector2.ZERO
		for cell in cells:
			if not cell == self:
				var escape_vec_update = position - cell.position
				escape_vec_update.x = 1 / escape_vec_update.x
				escape_vec_update.y = 1 / escape_vec_update.y
				
				escape_vector += escape_vec_update
			
		escape_vector = escape_vector.normalized()
		print(escape_vector)
		update()

func _draw():
	if not do_nothing:
		draw_line(Vector2.ZERO, escape_vector * 100, Color.blue, 10)

func get_sensed() -> Dictionary:
	var output = {}
	for sensed in $SenseArea.get_overlapping_areas():
		if sensed.get_groups().size() == 0:
			if output.has("untagged"):
				output["untagged"].append(sensed)
			else:
				output["untagged"] = [sensed]
		else:
			for group in sensed.get_groups():
				if output.has(group):
					output[group].append(sensed)
				else:
					output[group] = [sensed]
	
	return output
