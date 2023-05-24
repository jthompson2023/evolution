extends Node2D

export var dump_data := false
export var energy_drain := 0.0 # constant energy drain on all cells per second
var data = {}
onready var start_time = Time.get_ticks_msec()


func _ready():
	randomize()


func _process(delta):
	# ---- OPERATION -----
	
	for cell in $Cells.get_children():
		cell.energy -= energy_drain * delta
	
	# ------- LOGGING DATA -------
	
	var speeds := []
	for cell in $Cells.get_children():
		speeds.append(cell.speed)
	
	var label_text = """
	population: {pop}
	speed mean: {speed mean}
	   std dev (sample): {speed std dev}
	"""
	
	$Label.text = label_text.format({"pop": $Cells.get_child_count(),
	"speed mean": mean(speeds), "speed std dev": std_dev(speeds, true)})
	
	data[Time.get_ticks_msec()] = {"mean speed": mean(speeds), 
	"population": $Cells.get_child_count(), "sample_std_dev": std_dev(speeds, true)}


func mean(arr: Array) -> float:
	var output := 0.0
	for item in arr:
		output += item
	
	output /= max(1, arr.size())
	
	return output


func std_dev(arr: Array, sample: bool = false) -> float:
	var arr_mean := mean(arr)
	var output := 0.0
	for item in arr:
		output += pow(item - arr_mean, 2)
	
	if sample:
		output /= max(arr.size(), 2) - 1 # for a sample mean
	else:
		output /= arr.size()
	output = sqrt(output)
	
	return output

func _exit_tree():
	if dump_data:
		var file_out := File.new()
		file_out.open("res://Simulation data @ %s.json" % Time.get_datetime_string_from_system(), 
		File.WRITE)
		file_out.store_string(to_json(data))
		file_out.close()


func _on_StopTimer_timeout():
	print("stopping now")
	queue_free()


func _on_Pause_toggled(_button_pressed):
	if $Pause.pressed == true:
		print("pause")
		get_tree().paused = true
	else:
		print("unpause")
		get_tree().paused = false
