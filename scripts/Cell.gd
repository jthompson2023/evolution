extends Area2D

""" 
------ Cell.gd -------

All of the logic for an individual cell's life: moving, metabolizing, reproducing, and updating its
energy levels appropriately.

----------------------
"""

# MUTABLE GENOTYPE: the traits that vary with reproduction.
export var speed := 100.0 	# pixels per second.
export var size := 1.0 		# scale


# NON-MUTATING TRAITS: changeable in the engine, but are not changed by gameplay.
onready var rng := RandomNumberGenerator.new()	# used for normal distributions for reproduction.
export  var randomness := 0.25 					# how erratically the cell moves without a target.
export  var reproduction_threshold := 200.0 	# how much energy before the cell splits
export  var speed_mutation := 25.0 				# std dev for speed mutation during reproduction.
export  var size_mutation := 0.0				# same deal for speed.


# CHANGING VARIABLES: constantly change over the course of play.
export var energy := 100.0 				# kilopixels.
var direction     := Vector2.ZERO		# current direction of movement.
var target:          Node2D				# target node, if moving towards one. Used for draw_line.


func _ready():
	$Sprite.self_modulate = Color.from_hsv(speed / 500, 1, 1)	# Cell color reflects speed trait.
	scale = Vector2.ONE * size									# Cell scale reflects size trait.
	
	$EnergyBar.max_value = reproduction_threshold				# Energy bar range set to
	$EnergyBar.min_value = 0									#   [0, reproduction_threshold.]
	
	rng.randomize()												# setup RNG.


func _process(delta):
	if energy <= 0:							# Die if you have no energy.
		queue_free()
		return
	
	if energy >= reproduction_threshold:	# Reproduce if you have enough energy.
		reproduce(delta)
	
	move(delta)								# Move.
	expend_energy(delta)					# Burn energy required for above tasks.
	update()								# Update canvas drawings (for draw_line).


func expend_energy(delta):
	energy -= pow(speed, 2) * pow(size, 2) * delta / 1000		# Custom energy equation, drawn from
	$EnergyBar.value = energy									#  Primer's work.


func move(delta):
	direction = pick_target_and_direction(get_sensed())			# Choose a direction…
	translate(direction * speed * delta)						# …and move towards it.


func reproduce(delta):
	energy /= 2								# Split energy between self and new cell.
	var offspring = duplicate()				# Make offspring…
	get_parent().add_child(offspring)
	offspring.rng.randomize()
	offspring.speed = max(0, rng.randfn(speed, speed_mutation))		# …and mutate its traits with
	offspring.size = max(0.01, rng.randfn(size, size_mutation))		# a normal distribution.
	
	translate(direction * speed * delta * 100) 						# Launch forward.

# Given a list of sensed objects, pick where to go.
func pick_target_and_direction(sensed: Dictionary) -> Vector2:
	var output := Vector2.ZERO
	var sugars := []
	var prey := []
	var predators := []
	
	# Remove irrelevant objects.
	if sensed.has("untagged"):
		sensed.erase("untagged")
	
	# If nothing sensed, return a pseudorandom direction.
	if not sensed:
		target = null
		output = (direction + rand_vec() * randomness).normalized()
		return output
	
	# Sort cells into possible predators & prey.
	if sensed.has("cell"):
		for cell in sensed["cell"]:
			if cell.size / size >= 1.25: # If the other cell is 25% larger, it's a predator.
				predators.append(cell)
			elif size / cell.size >= 1.25: # If it's 25% smaller, it's potential prey.
				prey.append(cell)
	
	# Collect sugars for decision-making.
	if sensed.has("sugar"):
		sugars = sensed["sugar"]
	
	# If there are any possible predators, run away.
	if predators.size() > 0:
		target = null
		for predator in predators:
			var escape_vec: Vector2 = position - predator.position
			escape_vec = escape_vec.normalized() * (1 / escape_vec.length())
			output += escape_vec
		output = output.normalized()
		return output
	
	# Collect possible food sources
	var food: Array = sugars + prey
	
	# If there's nothing edible, just go random
	if food.size() == 0:
		target = null
		output = (direction + rand_vec() * randomness).normalized()
		return output
		
	# Otherwise, get the one that will provide the most net energy
	var closest_target: Node2D = food[0]
	var closest_target_distance: float = global_position.distance_squared_to(closest_target.global_position)
	var cost_per_distance := speed * pow(size, 2) / 1000 # Simplifying energy equation
	
	for item in food:
		var item_distance: float = global_position.distance_squared_to(item.global_position)
		if (item.energy - cost_per_distance * item_distance) > (closest_target.energy - cost_per_distance * closest_target_distance):
			closest_target = item
			closest_target_distance = item_distance

	
	target = closest_target
	output = global_position.direction_to(closest_target.global_position)
	
	return output


func _draw():
	if target != null:
		draw_line(Vector2.ZERO, (target.global_position - position) / scale, Color.green, 3 / size)


func get_sensed() -> Dictionary:
	var output = {}
	for sensed in $SenseArea.get_overlapping_areas():
		if sensed == self: # Do not include self
			continue
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


# Eat things!
func _on_Cell_area_entered(area: Area2D):
	# Things are edible if they're either:
	# 	1. sugars
	#	2. cells that are at least 25% smaller than you
	# If at least one of those conditions is met, destroy it and gain its energy.
	
	if (area.get_groups().has("sugar")) or (area.get_groups().has("cell") and size / area.size >= 1.25):
		energy += area.energy
		area.queue_free()
