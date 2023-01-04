extends Area2D

export var energy = 100 # In kilopixels.

func _on_Sugar_area_entered(area: Area2D):
	if "cell" in area.get_groups():
		area.energy += energy
		queue_free()
