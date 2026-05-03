extends Control 

func _ready():
	$SfxFin.play()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# 1. Récupérer le nom du gagnant sauvegardé dans Persosglobal
	var nom_gagnant = Persosglobal.dernier_gagnant_nom
	
	# 2. Chercher les infos du perso dans la liste globale pour avoir son portrait
	var portrait_path = ""
	
	for perso in Persosglobal.liste_persos.values():
		if perso["nom"] == nom_gagnant:
			portrait_path = perso["portrait"]
			break
			
	# 3. Afficher l'icône
	if $%IconeGagnant and portrait_path != "":
		$%IconeGagnant.texture = load(portrait_path)

	if $%ScoreLabel:
		$%ScoreLabel.text = "Le score est de : " + str(Persosglobal.score_final_p1) + " - " + str(Persosglobal.score_final_p2)
	if $%winner:
		$%winner.text = "Le gagnant est : " + nom_gagnant
	reouvrir_iris()
# Bouton REVANCHE : Relance le combat avec les MÊMES personnages
func _on_revanche_pressed():
	AudioManager.play("clique", global_position)
	# On peut réinitialiser les scores ici si besoin
	Persosglobal.score_final_p1 = 0
	Persosglobal.score_final_p2 = 0
	# On recharge la scène de combat (adapte le chemin si besoin)
	get_tree().change_scene_to_file("res://script global/gameplay.tscn")

# Bouton NOUVELLE PARTIE : Retourne à la sélection des personnages
func _on_nouvelleparti_pressed():
	# On change pour la scène de sélection
	AudioManager.play("clique", global_position)
	get_tree().change_scene_to_file("res://script global/champselect.tscn")


func _on_menu_pressed():
	AudioManager.play("clique", global_position)
	get_tree().change_scene_to_file("res://script global/menu.tscn")

func reouvrir_iris():
	var iris = $IrisTransition
	iris.visible = true

	# On part de 0 (tout noir)
	iris.material.set_shader_parameter("circle_size", 0.0)

	var tw = create_tween()
	# On ouvre vers 1.05 (tout visible)
	tw.tween_property(iris.material, "shader_parameter/circle_size", 1.05, 1.0).set_trans(Tween.TRANS_SINE)

	# Une fois fini, on peut cacher le nœud pour économiser de la ressource
	tw.finished.connect(func(): iris.visible = false)
