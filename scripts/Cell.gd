extends Area2D

# GENOTYPE
export var speed := 100.0 # pixels per second.
export var speed_mutation := 25.0 # std dev for mutating speed
export var size := 1.0 # scale
export var size_mutation := 0.25

# NON-MUTATING TRAITS
onready var rng := RandomNumberGenerator.new()
export var randomness := 0.25 # how erratically the cell moves when it has no target.
export var reproduction_threshold := 200.0 # how much energy before the cell splits

# CHANGING VARIABLES
export var energy := 100.0 # kilopixels.
var direction := Vector2.ZERO
var target: Node2D


func _ready():
	$Sprite.self_modulate = Color.from_hsv(speed / 500, 1, 1)
	$EnergyBar.max_value = reproduction_threshold
	$EnergyBar.min_value = 0
	rng.randomize()

func _process(delta):
	if size != scale.x or size != scale.y:
		scale = Vector2.ONE * size
	
	if energy <= 0:
		queue_free()
		return
	
	if energy >= reproduction_threshold:
		reproduce(delta)
	
	direction = pick_target_and_direction(get_sensed())
	
	translate(direction * speed * delta)
	energy -= pow(speed, 2) * pow(size, 2) * delta / 1000 # energy cost of MOVEMENT
	
	$EnergyBar.value = energy
	update()

func reproduce(delta):
	energy /= 2
	var offspring = duplicate()
	get_parent().add_child(offspring)
	offspring.rng.randomize()
	offspring.speed = max(0, rng.randfn(speed, speed_mutation)) # Ensures no negative speed
	translate(direction * speed * delta * 100)

func pick_target_and_direction(sensed: Dictionary) -> Vector2:
	var output := Vector2.ZERO
	var sugars := []
	var prey := []
	var predators := []
	
	# If nothing sensed, return a pseudorandom direction.
	if sensed == null:
		target = null
		output = (direction + rand_vec() * randomness).normalized()
		return output
	
	# Sort cells into possible predators & prey.
	if sensed.has("cell"):
		for cell in sensed["cell"]:
			if cell == self:
				continue
			if cell.size >= size * 1.25:
				predators.append(cell)
			elif cell.size * 1.25 <= size:
				prey.append(cell)
	
	# Collect sugars for decision-making.
	if sensed.has("sugar"):
		sugars = sensed["sugar"]
	
	# If there are any possible predators, run away.
	if predators.size() > 0:
		target = null
		for predator in predators:
			var escape_vec: Vector2 = position - predator.position
			escape_vec *= 1 / escape_vec.length()
			output += escape_vec
		output = output.normalized()
		return output
	
	# Otherwise, hunt the food that will give the greatest net energy boost.
	var food: Array = sugars + prey
	var closest_target: Node2D
	
	for item in food:
		
	
	"""if sensed != null and sensed.has("sugar"):
		target = closest_node(sensed["sugar"])
		output = (target.global_position - position).normalized()
	else:
		target = null
		output = (direction + rand_vec() * randomness).normalized()"""
	
	return output

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
