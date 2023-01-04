extends Node2D

var data = {}
onready var start_time = Time.get_ticks_msec()


func _ready():
	randomize()


func _process(_delta):
	var speeds := []
	for cell in $Cells.get_children():
		speeds.append(cell.speed)
	
	var label_text = """
	population: {pop}
	speed mean: {speed mean}
	   std dev: {speed std dev}
	"""
	
	$Label.text = label_text.format({"pop": $Cells.get_child_count(),
	"speed mean": mean(speeds), "speed std dev": std_dev(speeds)})
	
	data[Time.get_ticks_msec()] = {"mean speed": mean(speeds), 
	"population": $Cells.get_child_count()}


func mean(arr: Array) -> float:
	var output := 0.0
	for item in arr:
		output += item
	
	output /= arr.size()
	
	return output

func std_dev(arr: Array) -> float:
	var arr_mean := mean(arr)
	var output := 0.0
	for item in arr:
		output += pow(item - arr_mean, 2)
	
	output /= arr.size()
	output = sqrt(output)
	
	return output

func _exit_tree():
	var file_out := File.new()
	file_out.open("res://Simulation data @ %s.json" % Time.get_datetime_string_from_system(), 
	File.WRITE)
	file_out.store_string(to_json(data))
	file_out.close()
	


func _on_StopTimer_timeout():
	queue_free()
