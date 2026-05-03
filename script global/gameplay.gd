extends Control

# --- RÉFÉRENCES ---
@onready var camera = %Camera2D
@onready var label_countdown = $CanvasLayer/cddepart
@onready var chrono = %chrono
@onready var splash_art = $CanvasLayer/SplashArtUlti
@onready var carcan_ulti_p1 = %carcan_ulti_p1
@onready var icon_ulti_p1 = carcan_ulti_p1.get_child(0)

@onready var bar_p1 = $CanvasLayer/barredevie/VBoxContainer/HBoxContainer/VBoxContainer/J1HEALTH
@onready var bar_p2 = $CanvasLayer/barredevie/VBoxContainer/HBoxContainer/VBoxContainer2/J2HEALTH

@onready var carcan_ulti_p2 = %carcan_ulti_p2 
@onready var icon_ulti_p2 = carcan_ulti_p2.get_child(0)
@onready var portrait_ui_p1 = %portrait_p1 
@onready var portrait_ui_p2 = %portrait_p2

# --- VARIABLES ---
var rounds_p1 = 0
var rounds_p2 = 0
const ROUNDS_POUR_GAGNER = 2
var dernier_gagnant_nom = ""
var score_final_p1 = 0
var score_final_p2 = 0
var hp_p1 = 450
var hp_p2 = 450
var energie_p1 = 0	
var energie_p2 = 0
var combat_actif = false
var temps = 180
var compte_a_rebours = 3
var shake_intensity : float = 0.0
var taille_voulue = 0.5
var extension_active = false
var territory_owner : int = 0
var type_extension_actuelle = ""
@onready var vsp = $VideoStreamPlayer# Ton fond actuel
# Prépare un Sprite ou un ColorRect noir/violet pour le fond de l'ultime
var video_base = preload("res://ui_design/fond-animé_1.ogv")
var video_brillon = preload("res://persos/brillon/bg_ult_brillon.ogv")
var video_dallaporta = preload("res://song/cyberpunk-rain-city-pixel-moewalls-com.ogv")
func _ready():
	# On fixe le zoom une fois pour toutes pour éviter les décalages
	reouvrir_iris()
	splash_art.modulate.a = 0
	if has_node("%VideoStreamPlayer"):
		%VideoStreamPlayer.play()
		
	spawn_joueurs()
	
	var centre_initial = ($p1.global_position + $p2.global_position) / 2
	camera.global_position = centre_initial
	camera.zoom = Vector2(0.8, 0.8)
	
	
	
	
	mettre_a_jour_ui()
	demarrer_sequence_intro()

# --- BOUCLE PRINCIPALE ---
func _process(delta):
	if has_node("p1") and has_node("p2"):
		var p1 = $p1
		var p2 = $p2
		
		# SUPPRESSION DES LIGNES p1.peut_bouger = combat_actif
		
		var target_pos = (p1.global_position + p2.global_position) / 2
		if shake_intensity > 0:
			target_pos += Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake_intensity
			shake_intensity = move_toward(shake_intensity, 0.0, delta * 100.0)
		camera.global_position = target_pos
		
		mettre_a_jour_ui()
		

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"): # Touche Echap par défaut
		toggle_pause()

# --- GESTION DES JOUEURS ---
func spawn_joueurs():
	# --- JOUEUR 1 ---
	
	var p1_res = Persosglobal.liste_persos[Persosglobal.choix_p1]
	var p1_instance = load(p1_res["scene"]).instantiate()
	p1_instance.name = "p1"
	p1_instance.peut_bouger = false
	add_child(p1_instance)
	
	# Synchronisation des stats et UI pour P1
	hp_p1 = p1_instance.hp_max # Récupère les 1050 de Garric ou les HP des autres
	bar_p1.max_value = hp_p1
	bar_p1.value = hp_p1
	
	if p1_res.has("portrait"): 
		portrait_ui_p1.texture = load(p1_res["portrait"])
	
	p1_instance.global_position = %spawnJ1.global_position
	p1_instance.scale = Vector2(taille_voulue, taille_voulue)
	p1_instance.set_player_id(1)
	
	if p1_instance.get("icone_ultime"): 
		icon_ulti_p1.texture = p1_instance.icone_ultime

	# --- JOUEUR 2 ---
	var p2_res = Persosglobal.liste_persos[Persosglobal.choix_p2]
	var p2_instance = load(p2_res["scene"]).instantiate()
	p2_instance.name = "p2"
	p2_instance.peut_bouger = false
	add_child(p2_instance)
	
	# Synchronisation des stats et UI pour P2
	hp_p2 = p2_instance.hp_max
	bar_p2.max_value = hp_p2
	bar_p2.value = hp_p2
	
	if p2_res.has("portrait"): 
		portrait_ui_p2.texture = load(p2_res["portrait"])
	
	p2_instance.global_position = %spawnJ2.global_position
	p2_instance.scale = Vector2(taille_voulue, taille_voulue)
	p2_instance.set_player_id(2)
	
	# On s'assure que le J2 regarde vers la gauche
	if p2_instance.has_node("AnimatedSprite2D"):
		p2_instance.get_node("AnimatedSprite2D").flip_h = true
		
	if p2_instance.get("icone_ultime"): 
		icon_ulti_p2.texture = p2_instance.icone_ultime

	# Log de vérification dans la console
	print("P1 Spawning: ", Persosglobal.choix_p1, " avec ", hp_p1, " HP")
	print("P2 Spawning: ", Persosglobal.choix_p2, " avec ", hp_p2, " HP")

# On ajoute le paramètre 'donne_energie' qui est vrai (true) par défaut
func infliger_degats(frappeur_id, donne_energie = true):
	var degats = 25.0
	var cible = $p2 if frappeur_id == 1 else $p1
	var frappeur = $p1 if frappeur_id == 1 else $p2
	var victime = $p2 if frappeur_id == 1 else $p1
	# --- LOGIQUE DE PERTE DE TEMPS (DALLAPORTA UNIQUEMENT) ---
	if victime.has_method("perdre_temps_ultime"):
		victime.recevoir_coup() # Brise son invisibilité
		
		if extension_active and type_extension_actuelle == "Dallaporta" and territory_owner == victime.player_id:
			victime.perdre_temps_ultime(10.0)
	
	if cible.en_blocage:
		print("BLOCAGE PARFAIT !")
		shake_intensity = 2.0
		return
		
	elif cible.en_parade:
		hp_p1 -= degats * 0.5
		hp_p2 -= degats * 0.5
		shake_intensity = 15.0
	else:
		if frappeur_id == 1: hp_p2 -= degats
		else: hp_p1 -= degats
		shake_intensity = 15.0
		
	if victime.has_method("recevoir_coup_passif"):
		victime.recevoir_coup_passif(frappeur)
	
	# --- LOGIQUE D'ÉNERGIE ---
	# On n'ajoute de l'énergie QUE SI donne_energie est vrai
	if donne_energie:
		if frappeur_id == 1 and energie_p1 < 100: 
			energie_p1 = clamp(energie_p1 + 8, 0, 100)
			if energie_p1 >= 100: feedback_ulti_pret(1)
		elif frappeur_id == 2 and energie_p2 < 100: 
			energie_p2 = clamp(energie_p2 + 8, 0, 100)
			if energie_p2 >= 100: feedback_ulti_pret(2)
	
	mettre_a_jour_ui()
	verifier_mort()

# --- FEEDBACKS & UI ---
func feedback_ulti_pret(p_id):
	shake_intensity = 20.0
	var label_ulti = Label.new()
	label_ulti.text = "ULTIME J" + str(p_id) + " PRÊT !"
	label_ulti.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_ulti.add_theme_font_size_override("font_size", 70)
	label_ulti.modulate = Color.YELLOW if p_id == 1 else Color.CYAN
	label_ulti.add_theme_constant_override("outline_size", 12)
	label_ulti.add_theme_color_override("font_outline_color", Color.BLACK)
	$CanvasLayer.add_child(label_ulti)
	var screen_size = get_viewport_rect().size
	label_ulti.custom_minimum_size = Vector2(screen_size.x, 100)
	label_ulti.position = Vector2(0, (screen_size.y / 2) - 100)
	label_ulti.pivot_offset = Vector2(screen_size.x / 2, 50)
	label_ulti.scale = Vector2(0, 0)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(label_ulti, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK)
	tw.tween_property(label_ulti, "modulate:a", 0, 0.5).set_delay(1.5)
	tw.finished.connect(func(): label_ulti.queue_free())

func appliquer_visuel_ulti_pret(icone):
	AudioManager.play("energie", global_position)
	if icone.has_meta("flash_tween"):
		var old_tw = icone.get_meta("flash_tween")
		if old_tw: old_tw.kill()
	icone.visible = true
	icone.modulate.a = 1.0
	var tw = create_tween().set_loops()
	tw.tween_property(icone.material, "shader_parameter/pulse_weight", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	tw.tween_property(icone.material, "shader_parameter/pulse_weight", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	icone.set_meta("flash_tween", tw)

func appliquer_visuel_ulti_utilise(icone):
	if icone.has_meta("flash_tween"):
		var tw = icone.get_meta("flash_tween")
		if tw: tw.kill()
		icone.remove_meta("flash_tween")
	icone.material.set_shader_parameter("pulse_weight", 0.0)
	icone.visible = false

func mettre_a_jour_ui():
	bar_p1.value = hp_p1
	bar_p2.value = hp_p2
	update_triple_bar(%barrecontainer, energie_p1, 1)
	update_triple_bar(%barrecontainer2, energie_p2, 2)
	var j1 = get_node_or_null("p1") 
	if j1 and icon_ulti_p1: icon_ulti_p1.texture = j1.icone_ultime
	var j2 = get_node_or_null("p2") 
	if j2 and icon_ulti_p2: icon_ulti_p2.texture = j2.icone_ultime
	
func update_triple_bar(container, valeur, p_id):
	var bars = [container.get_node("ProgressBar"), container.get_node("ProgressBar2"), container.get_node("ProgressBar3")]
	var icone = icon_ulti_p1 if p_id == 1 else icon_ulti_p2
	for i in range(3):
		bars[i].value = clamp((valeur - (i * 33.3)) * 3, 0, 100)
	if valeur > 0.1: 
		if valeur >= 100 or (valeur < 100 and icone.get_meta("en_cours_d_utilisation", false)):
			if not icone.has_meta("flash_tween") or not icone.get_meta("flash_tween").is_running():
				appliquer_visuel_ulti_pret(icone)
	elif valeur <= 0.1:
		if icone.has_meta("flash_tween"):
			icone.set_meta("en_cours_d_utilisation", false)
			appliquer_visuel_ulti_utilise(icone)

# --- CINÉMATIQUES & CAMERA ---
func zoom_cinematique(cible):
	#combat_actif = false 
	var adversaire = $p2 if cible.name == "p1" else $p1
	adversaire.visible = false 
	if has_node("MonDecor"):
		var tw_decor = create_tween()
		tw_decor.tween_property($MonDecor, "modulate", Color(0, 0, 0, 1.0), 2)

func reset_camera():
	$p1.visible = true
	$p2.visible = true
	if has_node("MonDecor"):
		var tw_decor = create_tween()
		tw_decor.tween_property($MonDecor, "modulate", Color(1, 1, 1, 1), 2)
	combat_actif = true

# Dans gameplay.gd
func afficher_splashart_ulti(p_id, image_splash, lancer_pouvoir = true): # true par défaut
	splash_art.texture = image_splash
	splash_art.modulate.a = 0
	splash_art.visible = true
	
	var tw = create_tween()
	tw.tween_property(splash_art, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.0)
	tw.tween_property(splash_art, "modulate:a", 0.0, 0.2)
	
	tw.finished.connect(func(): 
		splash_art.visible = false
		# ON NE LANCE L'EXTENSION QUE SI C'EST DEMANDÉ
		if lancer_pouvoir:
			activer_extension(p_id)
	)
# --- SEQUENCE INTRO & CHRONO ---
func demarrer_sequence_intro():
	if compte_a_rebours > 0:
		label_countdown.text = str(compte_a_rebours)
		compte_a_rebours -= 1
		get_tree().create_timer(1.0).timeout.connect(demarrer_sequence_intro)
	else:
		# Cette partie s'exécute quand le chrono arrive à 0
		label_countdown.text = "FIGHT !"
		combat_actif = true
		
		# ON ACTIVE LES JOUEURS ICI (Une seule fois)
		if has_node("p1"): $p1.peut_bouger = true
		if has_node("p2"): $p2.peut_bouger = true
		
		demarrer_chrono()
		
		# ON CACHE LE LABEL APRÈS 1 SECONDE
		await get_tree().create_timer(1.0).timeout
		label_countdown.visible = false

func demarrer_chrono():
	await get_tree().create_timer(1.0, false).timeout
	if combat_actif and temps > 0:
		temps -= 1
		chrono.text = str(temps)
		
		if temps <= 0:
			timer_termine_decision_hp() # On appelle la décision par HP
		else:
			demarrer_chrono()
		

func verifier_mort():
	if not combat_actif: 
		return	
	if hp_p1 <= 0 or hp_p2 <= 0:
		combat_actif = false
		
		# Effet de ralenti (Slow Motion)
		Engine.time_scale = 0.2 # Le jeu tourne à 20% de sa vitesse
		
		# On attend un peu (en temps réel, donc on utilise un timer spécial)
		await get_tree().create_timer(1.5 * Engine.time_scale).timeout
		
		# On remet la vitesse normale
		Engine.time_scale = 1.0
		
		# 1. Attribution du point
		if hp_p1 <= 0:
			rounds_p2 += 1
			label_countdown.text = "ROUND JOUEUR 2 !"
		else:
			rounds_p1 += 1
			label_countdown.text = "ROUND JOUEUR 1 !"
		
		label_countdown.visible = true
		print("Score actuel : P1: ", rounds_p1, " | P2: ", rounds_p2)

		# 2. Vérification de la victoire finale
		if rounds_p1 >= ROUNDS_POUR_GAGNER or rounds_p2 >= ROUNDS_POUR_GAGNER:
			afficher_ecran_fin_match()
		else:
			# 3. On attend un peu et on relance le round suivant
			get_tree().create_timer(2.0).timeout.connect(preparer_round_suivant)

# --- AUDIO & INPUT ---
func gerer_musique_combat(actif: bool):
	if has_node("MusiqueFond"):
		$MusiqueFond.volume_db = 0 if actif else -80

func stopper_tous_les_sons_ultime():
	if has_node("p1"): $p1.audio_s.stop()
	if has_node("p2"): $p2.audio_s.stop()
	gerer_musique_combat(false)

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		var objet = get_viewport().gui_get_hovered_control()
		if objet: print("Ta souris a cliqué sur : ", objet.name)

func activer_extension(lanceur_id):
	extension_active = true
	territory_owner = lanceur_id
	
	# --- DÉTECTION DU JOUEUR ---
	var frappeur = $p1 if lanceur_id == 1 else $p2
	
	# --- DÉTECTION DU TYPE D'EXTENSION (INTELLIGENTE POUR HECKER) ---
	# Si le perso a un 'ultime_vole' non nul (cas de Hecker), on prend ce type.
	# Sinon, on prend le nom du personnage d'origine.
	if "ultime_vole" in frappeur and frappeur.ultime_vole != null:
		type_extension_actuelle = frappeur.ultime_vole
	else:
		var p_res = Persosglobal.liste_persos[Persosglobal.choix_p1 if lanceur_id == 1 else Persosglobal.choix_p2]
		type_extension_actuelle = p_res["nom"]
	print("TYPE D'EXTENSION ACTIVÉ : ", type_extension_actuelle)
	
	# --- PHASE 1 : IMPACT VISUEL (LA BRISURE) ---
	shake_intensity = 60.0
	
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color.WHITE
	$CanvasLayer.add_child(flash)
	
	if has_node("CanvasLayer/EcranBrisi"):
		$CanvasLayer/EcranBrisi.visible = true
		$CanvasLayer/EcranBrisi.modulate.a = 1.0

	# --- PHASE 2 : CHANGEMENT DE DÉCOR VIDÉO ---
	if has_node("VideoStreamPlayer"):
		var vsp = $VideoStreamPlayer
		vsp.stop()
		
		# On utilise .to_lower() pour éviter les erreurs de majuscules/minuscules
		var nom_test = type_extension_actuelle.to_lower()
		
		if nom_test == "brillon":
			vsp.stream = video_brillon # Assure-toi que cette variable est bien déclarée en haut
		elif nom_test == "dallaporta" or "hecker":
			vsp.stream = video_dallaporta # Assure-toi que cette variable est bien déclarée en haut
		
		vsp.play()
		
		# Transition fluide pour enlever le flash et les fissures
		var tw_trans = create_tween().set_parallel(true)
		tw_trans.tween_property(flash, "color:a", 0.0, 0.4)
		if has_node("CanvasLayer/EcranBrisi"):
			tw_trans.tween_property($CanvasLayer/EcranBrisi, "modulate:a", 0.0, 0.8)
		
		tw_trans.finished.connect(func(): flash.queue_free())

	# --- PHASE 3 : GESTION DE LA DURÉE ---
	# Pour Brillon : Durée fixe de 30 secondes gérée par le gameplay.
	if type_extension_actuelle.to_lower() == "brillon":
		await get_tree().create_timer(30.0).timeout
		# On vérifie que l'extension est toujours active avant de couper
		if extension_active and type_extension_actuelle.to_lower() == "brillon":
			fin_extension_visuelle()
			
	# Pour Dallaporta : La fin est gérée directement dans le script du perso 
	# (dallaporta.gd ou hecker.gd) via l'appel à fin_extension_visuelle().

func fin_extension_visuelle():
	if not extension_active: return
	
	extension_active = false
	territory_owner = 0
	type_extension_actuelle = ""
	
	# Secousse de sortie
	shake_intensity = 40.0
	
	# Retour au fond normal
	if has_node("VideoStreamPlayer"):
		vsp.stop()
		vsp.stream = video_base
		vsp.play()
	
	print("Retour au monde normal")

func toggle_pause():
	AudioManager.play("clique", global_position)
	# 1. On inverse l'état de pause global
	var current_state = get_tree().paused
	get_tree().paused = !current_state
	
	# 2. On synchronise le menu avec cet état
	var pause_menu = $%menu
	pause_menu.visible = !current_state

	if !current_state: # Si on vient de mettre en pause
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else: # Si on reprend le jeu
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed():
	get_tree().paused = false      # Relance le temps
	$%menu.visible = false     # Cache le menu
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Cache la souris

func _on_retour_lobby_pressed():
	get_tree().paused = false # TRÈS IMPORTANT : Relancer le temps avant de changer de scène
	get_tree().change_scene_to_file("res://script global/champselect.tscn")

func _on_btn_lobby_pressed():
	get_tree().paused = false # TRÈS IMPORTANT : Relancer le temps avant de changer de scène
	get_tree().change_scene_to_file("res://script global/menu.tscn")


func preparer_round_suivant():
	# 1. Reset des HP
	hp_p1 = $p1.hp_max
	hp_p2 = $p2.hp_max
	
	# 2. RESET DE L'ÉNERGIE (Nouveau)
	energie_p1 = 0
	energie_p2 = 0
	
	# 3. Nettoyage des effets visuels d'ultime
	if has_node("p1"): appliquer_visuel_ulti_utilise(icon_ulti_p1)
	if has_node("p2"): appliquer_visuel_ulti_utilise(icon_ulti_p2)
	
	# On arrête les effets visuels (vidéo, tremblements)
	fin_extension_visuelle()
	
	# On replace les joueurs aux spawns
	$p1.global_position = %spawnJ1.global_position
	$p2.global_position = %spawnJ2.global_position
	
	# 4. Mise à jour de l'UI pour refléter le reset
	mettre_a_jour_ui()
	
	# Reset du chrono et relance de la séquence
	temps = 180
	chrono.text = str(temps)
	compte_a_rebours = 3
	demarrer_sequence_intro()

func afficher_ecran_fin_match():
	# 1. Sauvegarder les résultats dans le script Global
	if rounds_p1 >= 2:
		Persosglobal.dernier_gagnant_nom = Persosglobal.liste_persos[Persosglobal.choix_p1]["nom"]
	else:
		Persosglobal.dernier_gagnant_nom = Persosglobal.liste_persos[Persosglobal.choix_p2]["nom"]

	Persosglobal.score_final_p1 = rounds_p1
	Persosglobal.score_final_p2 = rounds_p2

	# 2. S'assurer que le temps n'est pas figé avant de partir
	Engine.time_scale = 1.0
	get_tree().paused = false
	# 3. Changer totalement de scène
	transition_vers_resultats_iris()
	
	
func timer_termine_decision_hp():
	combat_actif = false
	
	# Calcul du pourcentage de vie restante (0.0 à 1.0)
	var ratio_p1 = float(hp_p1) / float($p1.hp_max)
	var ratio_p2 = float(hp_p2) / float($p2.hp_max)
	
	if ratio_p1 > ratio_p2:
		# P1 a un meilleur pourcentage, il gagne le round
		rounds_p1 += 1
		label_countdown.text = "J1 GAGNE AU HP !"
	elif ratio_p2 > ratio_p1:
		# P2 a un meilleur pourcentage
		rounds_p2 += 1
		label_countdown.text = "J2 GAGNE AU HP !"
	else:
		# Égalité parfaite
		label_countdown.text = "ÉGALITÉ !"
	
	label_countdown.visible = true
	
	# On attend 2 secondes et on vérifie si quelqu'un a gagné le match
	await get_tree().create_timer(2.0).timeout
	if rounds_p1 >= ROUNDS_POUR_GAGNER or rounds_p2 >= ROUNDS_POUR_GAGNER:
		afficher_ecran_fin_match()
	else:
		preparer_round_suivant()

func transition_vers_resultats_iris():
	var iris = $%IrisTransition
	iris.visible = true
	iris.material.set_shader_parameter("circle_size", 1.05)
	var tw = create_tween()
	tw.tween_property(iris.material, "shader_parameter/circle_size", 0.0, 1.2).set_trans(Tween.TRANS_SINE)
	await tw.finished
	get_tree().change_scene_to_file("res://script global/fin_combat.tscn")

func reouvrir_iris():
	var iris = $%TransiOut
	iris.visible = true

	# On part de 0 (tout noir)
	iris.material.set_shader_parameter("circle_size", 0.0)

	var tw = create_tween()
	# On ouvre vers 1.05 (tout visible)
	tw.tween_property(iris.material, "shader_parameter/circle_size", 1.05, 1.0).set_trans(Tween.TRANS_SINE)

	# Une fois fini, on peut cacher le nœud pour économiser de la ressource
	tw.finished.connect(func(): iris.visible = false);
