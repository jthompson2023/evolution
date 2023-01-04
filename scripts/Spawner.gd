tool
extends Node2D

export (PackedScene) var spawn_object
export (float) var radius = 400.0
export (Color) var draw_color = Color(0.4, 0.2, 0.6, 0.2)
export (bool) var draw_in_game = true

func _process(_delta):
	if Engine.editor_hint or draw_in_game:
		update()


func _draw():
	if Engine.editor_hint or draw_in_game:
		draw_circle(Vector2.ZERO, radius, draw_color)


func rand_vec():
	return Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()


func _on_SpawnTimer_timeout():
	var new_spawn: Node2D = spawn_object.instance()
	
	new_spawn.position = rand_vec() * (radius * randf())
	add_child(new_spawn)
