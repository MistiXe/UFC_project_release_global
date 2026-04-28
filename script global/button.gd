extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass




func _on_pressed() -> void:
	print("CLIC DÉTECTÉ !") # Si ça ne s'affiche pas en bas dans la console, le signal est mal branché
	get_tree().paused = !get_tree().paused
	
