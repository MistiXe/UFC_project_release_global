extends Control

# Liste de tes images de tutoriel (à placer dans ton dossier assets)
var slides = [
	preload("res://ui_design/asset1_tutov2.png"),
	preload("res://ui_design/unwatermarked_hayyaa.png")
	
]

var index_actuel = 0

@onready var affichage = $%AfficheImage
@onready var label_page = $%LabelPage

func _ready():
	_maj_affichage()

func _maj_affichage():
	# On change l'image
	affichage.texture = slides[index_actuel]
	# On met à jour le texte (ex: "Page 1 / 3")
	label_page.text = str(index_actuel + 1) + " / " + str(slides.size())
	
	# Optionnel : Griser les boutons si on est au début ou à la fin
	$gauche.disabled = (index_actuel == 0)
	$droite.disabled = (index_actuel == slides.size() - 1)

func _on_btn_droite_pressed():
	if index_actuel < slides.size() - 1:
		index_actuel += 1
		_maj_affichage()
		AudioManager.play("clic") # Petit SFX de page qui tourne

func _on_btn_gauche_pressed():
	if index_actuel > 0:
		index_actuel -= 1
		_maj_affichage()
		AudioManager.play("clic")

func _on_btn_quitter_pressed():
	get_tree().change_scene_to_file("res://script global/menu.tscn")
