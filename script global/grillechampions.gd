extends GridContainer

enum Etat {J1_CHOISIT, J1_CONFIRME, J2_CHOISIT, J2_CONFIRME, FINI}
var etat_actuel = Etat.J1_CHOISIT

var bouton_selectionne = null
var selection_p1 = null
var selection_p2 = null
var temps_restant = 5

@onready var titre_haut = %titre_haut
@onready var portrait_p1 = %p1 
@onready var portrait_p2 = %p2 

func _ready():
	# Animation d'entrée de la grille
	self.modulate.a = 0
	var tw_entree = create_tween()
	tw_entree.tween_property(self, "modulate:a", 1.0, 0.5)
	
	titre_haut.add_theme_font_size_override("font_size", 50)
	%BoutonTous.pressed.connect(filtrer_champions.bind("Tous", %BoutonTous))
	%BoutonAttaque.pressed.connect(filtrer_champions.bind("Attaque",  %BoutonAttaque))
	%BoutonDefense.pressed.connect(filtrer_champions.bind("Defense", %BoutonDefense))
	# Initialisation du clignotement pour le J1
	if portrait_p1:
		_faire_clignoter(portrait_p1, true)
	for container in get_children():
	# On vérifie qu'on est bien sur tes conteneurs de persos (tes nœuds "Hecker", "Alexis")
	# et pas sur un signal ou un nœud caché
		if container is Control and container.get_child_count() >= 2:
			var bouton = container.get_child(0) 
			var label = container.get_child(1)
		
		# On met le nom
			label.text = container.name.capitalize()
		
		# IMPORTANT : On s'assure que le bouton laisse passer le clic au parent si besoin
			bouton.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# On reconnecte
			if not bouton.pressed.is_connected(_on_champion_clicked):
				bouton.pressed.connect(_on_champion_clicked.bind(bouton))
		
			bouton.button_down.connect(_on_champion_hold_start.bind(bouton))
			bouton.button_up.connect(_on_champion_hold_end)
	
	_maj_compte_champions()

func _on_champion_clicked(bouton):
	if bouton.disabled: return 
	
	bouton_selectionne = bouton
	
	if etat_actuel == Etat.J1_CHOISIT or etat_actuel == Etat.J1_CONFIRME:
		if portrait_p1:
			portrait_p1.texture = bouton.icon
			portrait_p1.modulate = Color(1, 1, 1, 1) # Force la luminosité
			_anime_portrait_zoom(portrait_p1)
		
		titre_haut.text = "P1 : VERROUILLER " + bouton.name.to_upper() + " ? "
		etat_actuel = Etat.J1_CONFIRME
		
	elif etat_actuel == Etat.J2_CHOISIT or etat_actuel == Etat.J2_CONFIRME:
		if bouton == selection_p1: return 
		
		if portrait_p2:
			portrait_p2.texture = bouton.icon
			portrait_p2.modulate = Color(1, 1, 1, 1) # Force la luminosité
			_anime_portrait_zoom(portrait_p2)
			
		titre_haut.text = "P2 : VERROUILLER " + bouton.name.to_upper() + " ? "
		etat_actuel = Etat.J2_CONFIRME

func _anime_portrait_zoom(node):
	node.pivot_offset = node.size / 2
	var tw = create_tween()
	node.scale = Vector2(0.8, 0.8)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _input(event):

	if event.is_action_pressed("ui_cancel"):
		_retour_arriere()
		
	if event.is_action_pressed("ui_accept"):
		valider_selection()

func valider_selection():
	if etat_actuel == Etat.J1_CONFIRME:
		selection_p1 = bouton_selectionne
		barrer_champion(selection_p1)
		
		# --- AJOUT ICI ---
		_maj_compte_champions() 
		
		_faire_clignoter(portrait_p1, false)
		if portrait_p2:
			_faire_clignoter(portrait_p2, true)
		etat_actuel = Etat.J2_CHOISIT
		if titre_haut: titre_haut.text = "AU TOUR DU JOUEUR 2"
		
	elif etat_actuel == Etat.J2_CONFIRME:
		selection_p2 = bouton_selectionne
		barrer_champion(selection_p2)
		
		# --- AJOUT ICI ---
		_maj_compte_champions()
		
		_faire_clignoter(portrait_p2, false)
		etat_actuel = Etat.FINI
		lancer_final()

func barrer_champion(bouton):
	bouton.disabled = true
	var taille_reduite = bouton.size * 0.8
	var tw = create_tween()
	# Utilisation de custom_minimum_size pour que J1 ne redevienne pas grand au clic de J2
	tw.tween_property(bouton, "custom_minimum_size", taille_reduite, 0.3).set_trans(Tween.TRANS_QUAD)

func lancer_final():
	if titre_haut: titre_haut.add_theme_color_override("font_color", Color.YELLOW)
	_boucle_timer()

func _boucle_timer():
	if temps_restant > 0:
		if titre_haut:
			titre_haut.text = "COMBAT DANS : " + str(temps_restant)
			titre_haut.pivot_offset = titre_haut.size / 2
			var tw = create_tween()
			titre_haut.scale = Vector2(1.4, 1.4)
			tw.tween_property(titre_haut, "scale", Vector2(1.0, 1.0), 0.2)
		
		var ecran = get_node_or_null("%ecrannoir")
		if ecran and temps_restant <= 3:
			ecran.modulate.a = 1.0 - (float(temps_restant) / 3.0)
			
		temps_restant -= 1
		get_tree().create_timer(1.0).timeout.connect(_boucle_timer)
	else:
		_changer_scene()

func _changer_scene():
	if selection_p1 and selection_p2:
		Persosglobal.choix_p1 = selection_p1.name
		Persosglobal.choix_p2 = selection_p2.name
		transition_vers_resultats_iris()

func _faire_clignoter(node, actif: bool):
	if not node: return
	
	# On tue les tweens existants sur l'alpha pour éviter les conflits
	var killer = create_tween()
	
	if actif:
		var tw = create_tween().set_loops()
		tw.tween_property(node, "modulate:a", 0.5, 1)
		tw.tween_property(node, "modulate:a", 1.0, 1)
	else:
		var tw = create_tween()
		tw.tween_property(node, "modulate:a", 1.0, 0.2)


func _on_champion_hold_start(bouton):
	print("c'est maintenu")
	var nom = bouton.name.to_lower()
	if Persosglobal.liste_persos.has(nom):
		var data = Persosglobal.liste_persos[nom]
		
		# On remplit le texte
		var texte = "[center][b][font_size=30]" + nom.to_upper() + "[/font_size][/b][/center]\n"
		#texte += "[center][color=gray]" + data["type"] + "[/color][/center]\n\n"
		#texte += data["description"] + "\n\n"
		#texte += "[color=yellow]" + data["stats"] + "[/color]"
		
		%label_info.text = texte
		
		# On affiche la popup
		%PopupInfo.show()
		
		# Petit effet de zoom pour l'apparition
		%PopupInfo.scale = Vector2(0.5, 0.5)
		%PopupInfo.pivot_offset = %PopupInfo.size / 2
		var tw = create_tween()
		tw.tween_property(%PopupInfo, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _on_champion_hold_end():
	%PopupInfo.hide()


func _retour_arriere():
	if etat_actuel == Etat.J1_CONFIRME:
		# On annule la présélection du J1
		etat_actuel = Etat.J1_CHOISIT
		titre_haut.text = "CHOISISSEZ VOTRE CHAMPION !"
		portrait_p1.texture = null # Ou une texture par défaut
		_maj_compte_champions()
	elif etat_actuel == Etat.J2_CHOISIT:
		selection_p1 = null # On libère la sélection
		_maj_compte_champions() # Le chiffre repasse à (2/2)
		# On revient au J1
		# (Il faudra rajouter une logique pour "débarrer" le perso du J1 si tu veux)
		etat_actuel = Etat.J1_CONFIRME
		_faire_clignoter(portrait_p2, false)
		_faire_clignoter(portrait_p1, true)
		titre_haut.text = "P1 : CONFIRMER ?"
		
	else:
		# Si on est au tout début, on peut retourner au menu principal
		get_tree().change_scene_to_file("res://menu.tscn")
func _maj_compte_champions():
	var total_prevu = Persosglobal.liste_persos.size()
	var deja_pris = 0
	
	# On compte combien de champions sont déjà verrouillés
	if selection_p1 != null:
		deja_pris += 1
	if selection_p2 != null:
		deja_pris += 1
		
	var reste = total_prevu - deja_pris
	
	# On s'assure que ça ne tombe pas en dessous de 0 par sécurité
	reste = max(0, reste)
	
	%TITRE_bas.text = "CHAMPIONS DISPONIBLES (" + str(reste) + "/" + str(total_prevu) + ") :"


func filtrer_champions(type_voulu: String, bouton_clique: Button):
	%BoutonTous.modulate = Color.WHITE
	%BoutonAttaque.modulate = Color.WHITE
	%BoutonDefense.modulate = Color.WHITE
	
	bouton_clique.modulate = Color.ORANGE
	for container in get_children():
		# On s'assure de ne toucher qu'aux slots de la grille
		if container is Control:
			var nom_perso = container.name.to_lower()
			
			# Cas 1 : On veut tout afficher
			if type_voulu == "Tous":
				# On n'affiche que si le perso existe dans le dico (évite les cadres vides)
				if Persosglobal.liste_persos.has(nom_perso):
					container.show()
				else:
					container.hide()
				continue
			
			# Cas 2 : Filtrage par type
			if Persosglobal.liste_persos.has(nom_perso):
				var data = Persosglobal.liste_persos[nom_perso]
				if data["type"].to_upper() == type_voulu.to_upper():
					container.show() # On montre si c'est le bon type
				else:
					container.hide() # On cache si c'est un autre type
			else:
				# Cas 3 : C'est une case vide (pas dans le dico), on CACHE toujours
				container.hide()

func transition_vers_resultats_iris():
	var iris = $%CircleTransi
	iris.visible = true
	iris.material.set_shader_parameter("circle_size", 1.05)
	var tw = create_tween()
	tw.tween_property(iris.material, "shader_parameter/circle_size", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	get_tree().change_scene_to_file("res://script global/transi.tscn")
