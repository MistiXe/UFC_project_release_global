extends Control

@onready var label = $%hex # Assure-toi que le nom correspond

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	$SfxIntro.play()
	
	# Initialisation : texte invisible
	label.modulate.a = 0
	
	var tw = create_tween()
	
	# 1. Apparition du texte avec la vague
	tw.tween_property(label, "modulate:a", 1.0, 1.0)
	
	# 2. On laisse la vague tourner pendant 2 secondes
	tw.tween_interval(2.0)
	
	# 3. L'effet "vague" s'estompe pour remettre les lettres en ligne
	# On anime l'amplitude de la vague vers 0
	tw.tween_method(modifier_amplitude_vague, 50.0, 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	
	# 4. Transition finale vers le menu
	tw.tween_interval(1.0)
	tw.finished.connect(func(): get_tree().change_scene_to_file("res://script global/menu.tscn"))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func modifier_amplitude_vague(valeur: float):
	# On reconstruit la ligne BBCode avec la nouvelle amplitude
	label.text = "[center][wave amp=" + str(valeur) + " freq=5.0 connected=1]HEXACORE[/wave][/center]"
