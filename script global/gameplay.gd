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
@onready var fond_normal = $VideoStreamPlayer# Ton fond actuel
# Prépare un Sprite ou un ColorRect noir/violet pour le fond de l'ultime
var video_territoire = preload("res://persos/brillon/bg_ult_brillon.ogv")# --- INITIALISATION ---
func _ready():
	# On fixe le zoom une fois pour toutes pour éviter les décalages
	
	splash_art.modulate.a = 0
	if has_node("%VideoStreamPlayer"):
		%VideoStreamPlayer.play()
		
	spawn_joueurs()
	
	var centre_initial = ($p1.global_position + $p2.global_position) / 2
	camera.global_position = centre_initial
	camera.zoom = Vector2(0.8, 0.8)
	
	
	
	bar_p1.max_value = 450
	bar_p2.max_value = 450
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
		
		

# --- GESTION DES JOUEURS ---
func spawn_joueurs():
	var p1 = load(Persosglobal.liste_persos[Persosglobal.choix_p1]["scene"]).instantiate()
	var data_p1 = Persosglobal.liste_persos[Persosglobal.choix_p1]
	p1.name = "p1"
	add_child(p1)
	if data_p1.has("portrait"): portrait_ui_p1.texture = load(data_p1["portrait"])
	p1.global_position = %spawnJ1.global_position
	print(p1.global_position)
	p1.scale = Vector2(taille_voulue, taille_voulue)
	p1.set_player_id(1)
	if p1.get("icone_ultime"): icon_ulti_p1.texture = p1.icone_ultime
	
	var p2 = load(Persosglobal.liste_persos[Persosglobal.choix_p2]["scene"]).instantiate()
	var data_p2 = Persosglobal.liste_persos[Persosglobal.choix_p2]
	p2.name = "p2"
	add_child(p2)
	if data_p2.has("portrait"): portrait_ui_p2.texture = load(data_p2["portrait"])
	p2.global_position = %spawnJ2.global_position
	print(p2.global_position)
	p2.scale = Vector2(taille_voulue, taille_voulue)
	p2.set_player_id(2)
	p2.get_node("AnimatedSprite2D").flip_h = true
	if p2.get("icone_ultime"): icon_ulti_p2.texture = p2.icone_ultime

func infliger_degats(frappeur_id):
	var degats = 25.0
	var cible = $p2 if frappeur_id == 1 else $p1
	var frappeur = $p1 if frappeur_id == 1 else $p2
	var victime = $p2 if frappeur_id == 1 else $p1
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
		# Si la victime est Garric, il accumule de l'inertie contre le frappeur
		victime.recevoir_coup_passif(frappeur)
	
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
	combat_actif = false 
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
	await get_tree().create_timer(1.0).timeout
	if combat_actif and temps > 0:
		temps -= 1
		chrono.text = str(temps)
	if temps > 0: 
		demarrer_chrono()
		

func verifier_mort():
	if hp_p1 <= 0 or hp_p2 <= 0:
		combat_actif = false
		label_countdown.text = "K.O. !"
		label_countdown.visible = true

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
	
	
	# --- PHASE 1 : LA BRISURE (Impact visuel) ---
	# 1. Tremblement immédiat et violent
	shake_intensity = 60.0 
	
	# 2. Flash et Brisure
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color.WHITE
	$CanvasLayer.add_child(flash)
	
	# Si tu as un sprite de fissures, on l'affiche
	if has_node("CanvasLayer/EcranBrisi"):
		$CanvasLayer/EcranBrisi.visible = true
		$CanvasLayer/EcranBrisi.modulate.a = 1.0

	# --- PHASE 2 : TRANSITION VERS LA VIDÉO ---
	if has_node("VideoStreamPlayer"):
		var video_normale = $VideoStreamPlayer.stream
		
		# On change la vidéo "derrière" le flash
		$VideoStreamPlayer.stop()
		$VideoStreamPlayer.stream = video_territoire
		$VideoStreamPlayer.play()
		
		# On fait disparaître le flash et les fissures progressivement
		var tw_trans = create_tween().set_parallel(true)
		tw_trans.tween_property(flash, "color:a", 0.0, 0.4)
		if has_node("CanvasLayer/EcranBrisi"):
			tw_trans.tween_property($CanvasLayer/EcranBrisi, "modulate:a", 0.0, 0.8)
		
		tw_trans.finished.connect(func(): flash.queue_free())

		# --- PHASE 3 : DURÉE DE L'EXTENSION ---
		await get_tree().create_timer(30.0).timeout
		
		# --- PHASE 4 : SORTIE (Nouvelle brisure pour revenir) ---
		shake_intensity = 40.0
		$VideoStreamPlayer.stop()
		$VideoStreamPlayer.stream = video_normale
		$VideoStreamPlayer.play()
	
	extension_active = false
	territory_owner = 0
