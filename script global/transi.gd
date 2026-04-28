extends Control

var temps_chargement = 10.0 # On utilise un float pour plus de précision
var temps_ecoule = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ColorRect/VBoxContainer/ProgressBar.value = 0
	$ColorRect/VBoxContainer/Label.text = "PREPARATION DU TERRAIN..."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# On fait avancer le temps à chaque image
	temps_ecoule += delta
	
	# On calcule le pourcentage (0 à 100)
	var progression = (temps_ecoule / temps_chargement) * 100
	%ProgressBar.value = progression
	
	# Optionnel : changer le texte selon l'avancement
	if progression > 30: %Label.text = "AFFUTAGE DES LAMES..."
	if progression > 70: %Label.text = "ENTREE DANS L'ARENE..."

	# Quand on atteint les 10 secondes
	if temps_ecoule >= temps_chargement:
		# On arrête le process pour éviter de charger 50 fois
		set_process(false) 
		# ENFIN, on lance le combat
		get_tree().change_scene_to_file("res://script global/gameplay.tscn")
