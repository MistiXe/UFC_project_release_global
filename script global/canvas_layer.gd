extends CanvasLayer

# @onready permet de faire le lien avec tes noeuds
@onready var menu = %menu

func _ready():
	# On s'assure que le menu est caché au lancement du jeu
	pass

# C'est ici que ton signal "on_pressed" du BoutonPause doit arriver
func _on_pause_button_pressed():
	# 1. On inverse l'état de la pause
	get_tree().paused = !get_tree().paused
	
	# 2. On affiche le menu si on est en pause, sinon on le cache
	if get_tree().paused:
		menu.show()
	else:
		menu.hide()

# Signal "on_pressed" de ton bouton QUITTER (dans le menu)
func _on_bouton_quitter_pressed():
	get_tree().paused = false # ON RELANCE LE TEMPS AVANT DE QUITTER
	get_tree().change_scene_to_file("res://menu.tscn")
