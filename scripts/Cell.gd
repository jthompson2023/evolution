extends Area2D

export var speed := 100.0 # pixels per second.
export var speed_mutation := 25.0 # std dev for mutating speed
export var energy := 100.0 # kilopixels.
export var randomness := 0.25 # how erratically the cell moves when it has no target.
export var reproduction_threshold := 200.0 # how much energy before the cell splits
var direction := Vector2.ZERO
var target: Node2D
onready var rng = RandomNumberGenerator.new()

func _ready():
	$Sprite.self_modulate = Color.from_hsv(speed / 500, 1, 1)
	$EnergyBar.max_value = reproduction_threshold
	$EnergyBar.min_value = 0
	rng.randomize()

func _process(delta):
	if energy <= 0:
		queue_free()
		return
	
	if energy >= reproduction_threshold:
		energy /= 2
		var offspring = duplicate()
		get_parent().add_child(offspring)
		offspring.rng.randomize()
		offspring.speed = max(0, rng.randfn(speed, speed_mutation)) # Ensures no negative speed
		translate(direction * speed * delta * 100)
	
	var sensed = get_sensed()

	direction = (direction + rand_vec() * randomness).normalized()
	if sensed != null and sensed.has("sugar"):
		target = closest_node(sensed["sugar"])
		direction = (target.global_position - position).normalized()
	else:
		target = null
	
	translate(direction * speed * delta)
	energy -= pow(speed, 2) * delta / 1000 # TODO: is this a good unit?
	
	$EnergyBar.value = energy
	update()

func _draw():
	if target != null:
		draw_line(Vector2.ZERO, target.global_position - position, Color.green, 3)

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

func rand_vec() -> Vector2:
	return Vector2(randf() * 2 - 1, randf() * 2 - 1).normalized()

func closest_node(nodes: Array) -> Node2D:
	var closest: Node2D = nodes[0]
	for node in nodes:
		if position.distance_squared_to(closest.position) > position.distance_squared_to(node.position):
			closest = node
	return closest
