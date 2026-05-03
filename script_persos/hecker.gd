
extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 700.0
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var hp_max = 650
var player_id = 1 
var ulti_en_cours = false
var est_en_train_d_aspirer = false
var cible_ultime = null

# --- ÉTATS ---
var peut_bouger = true # CHANGÉ À TRUE PAR DÉFAUT
var en_train_dattaquer = false
var en_parade = false 
var en_blocage = false
var timer_blocage = 0.0
var extension_active = false
var temps_restant_extension = 0.0
var bonus_degats_temporel = 0.0 
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0  # Ajustez selon la puissance voulue
var duree_dash : float = 0.15      # Temps pendant lequel le perso fonce

# --- ASSETS ---
var icone_ultime = preload("res://persos/hecker/assets_hecker/Vol ancestral.png")
var splash_ultime = preload("res://persos/hecker/splash_hecker_.png")
var splash_alexis = preload("res://persos/alexis/splashulti/parade.png")
var splash_brillon = preload("res://persos/brillon/splash_brillonv1.png")
var splash_garric = preload("res://persos/garric/garric_real_splash.png")
var splash_montaut = preload("res://persos/montaut/splash_ult_montautv3.png")
var splash_pouit = preload("res://persos/pouit/splash_ultv2.png")
var splash_dall = preload("res://persos/dallaporta/splash_ult_dallv2.png")
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Voleur de Sorts_hecker_theme.mp3")
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@export var becane_scene : PackedScene = preload("res://script_persos/becane_objet.tscn") # À charger avec ton fichier moto.tscn

#@onready var particules = $ParticulesGradient
var liste_personnages = ["Dallaporta", "Pouit","Brillon","Montaut","Alexis", "Garric"]

var ultime_vole = null          
var icone_origine = preload("res://persos/hecker/assets_hecker/Vol ancestral.png")

func _ready():
	if not audio_s.get_parent(): add_child(audio_s)
	appliquer_cote_initial()

func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_hitbox()

func _actualiser_hitbox():
	if has_node("HitboxPoing"):
		$HitboxPoing.position.x = -850 if sprite.flip_h else 80

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
		
	var territory_active = (
		gameplay.extension_active and 
		gameplay.territory_owner != player_id and 
		gameplay.type_extension_actuelle == "Brillon" # <--- IMPORTANT : On précise Brillon ici
	)
	var action_parade = "blocage_" + str(player_id)

	# --- 1. VERROU PESANTEUR (STUN GARRIC) ---
	if not peut_bouger:
		velocity.x = 0
		sprite.play("stay")
		_actualiser_hitbox()
		move_and_slide()
		return 
	gerer_dash(delta)
	# --- 2. LOGIQUE DE BLOCAGE (TERRITOIRE) ---
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1) 
		elif not en_parade:
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		if Input.is_action_pressed(action_parade) and is_on_floor() and not en_train_dattaquer:
			timer_blocage += delta
			velocity.x = 0
			sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) 
			if timer_blocage >= 0.5:
				en_blocage = true
				AudioManager.play("bloc", global_position)
				sprite.modulate = Color(0.1, 0.1, 0.1, 0.5)
		else:
			en_blocage = false
			timer_blocage = 0.0
			if not en_parade: sprite.modulate = Color(1, 1, 1, 1)
			
	if not en_dash:
		# --- 3. INPUTS & TERRITOIRE ---
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)

		# SAUT (Inversion territoire)
		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			if territory_active:
				velocity.y = JUMP_VELOCITY * 0.8
				var recul = 1000.0 if not sprite.flip_h else -1000.0
				velocity.x = -recul 
			else:
				velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed(action_ultime):
			if ultime_vole == null: phase_vol_ancestral()
			else: utiliser_ultime_vole()

		if Input.is_action_just_pressed(action_attaque):
			frapper()
		
		if extension_active:
			temps_restant_extension -= delta
			# Calcul du bonus (même si on l'utilise différemment, ça sert de timer)
			bonus_degats_temporel = (30.0 - temps_restant_extension) * 3.0
			
			if temps_restant_extension <= 0:
				fin_extension() # La fonction qui remet la vitesse normale et le décor

		# DÉPLACEMENT (Inversion territoire)
		var direction = Input.get_axis(move_left, move_right)
		if territory_active:
			direction = -direction 
		
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			_actualiser_hitbox()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# --- 4. GESTION DES ANIMATIONS (ANTI-ÉCRASEMENT) ---
		if not en_train_dattaquer:
			if not is_on_floor():
				sprite.play("jump")
			elif direction != 0:
				sprite.play("walk")
			else:
				sprite.play("stay")
		if est_en_train_d_aspirer and is_instance_valid(cible_ultime):
			# 1. Calcul du vecteur de direction vers Hecker
			var direction_gradient = (global_position - cible_ultime.global_position).normalized()
			
			# 2. Calcul de la distance
			var distance = global_position.distance_to(cible_ultime.global_position)
			
			# 3. Calcul de la force (le fameux "Gradient")
			# Plus la cible est loin, plus elle est aspirée fort
			var force_attraction = clamp(distance * 5.0, 500.0, 3000.0)
			
			# 4. On applique la vélocité directement sur la cible
			cible_ultime.velocity.x = direction_gradient.x * force_attraction
			
			# 5. On force la cible à bouger (car son propre physics_process est souvent bloqué par peut_bouger = false)
			cible_ultime.move_and_slide()
	move_and_slide()
func frapper():
	en_train_dattaquer = true
	anim_player.play("attaque")
	AudioManager.play("attaque", global_position)
	await anim_player.animation_finished
	en_train_dattaquer = false

func phase_vol_ancestral():
	var parent = get_parent()
	var energie = parent.energie_p1 if player_id == 1 else parent.energie_p2
	if energie >= 100:
		en_train_dattaquer = true
		parent.afficher_splashart_ulti(player_id, splash_ultime, false) 
		await get_tree().create_timer(0.2).timeout
		parent.zoom_cinematique(self)
		if anim_player.has_animation("ultime_hecker"):
			anim_player.play("ultime_hecker")
			await anim_player.animation_finished
		var choix_possibles = liste_personnages.duplicate()
		choix_possibles.erase("Hecker")
		ultime_vole = choix_possibles[randi() % choix_possibles.size()]
		
		# AJOUTE ÇA ICI :
		if ultime_vole == "Garric":
			icone_ultime = preload("res://persos/garric/icon_garric_splash.png")
		elif ultime_vole == "Alexis":
			icone_ultime = preload("res://persos/parade_icon_ultime.png")
		elif ultime_vole == "Brillon":
			icone_ultime = preload("res://persos/brillon/logo_ult_bri2.png")
		elif ultime_vole == "Montaut":
			icone_ultime = preload("res://persos/montaut/icon_descente.png")	
		elif ultime_vole == "Pouit":
			icone_ultime = preload("res://persos/pouit/icon_ult.png")	
		elif ultime_vole == "Dallaporta":
			icone_ultime = preload("res://persos/dallaporta/splash_iconv2.png")
			
		parent.mettre_a_jour_ui() # Pour que l'icône apparaisse sur la barre
		parent.reset_camera()
		en_train_dattaquer = false

func set_player_id(id):
	player_id = id
	if not is_node_ready(): await ready
	appliquer_cote_initial()

func _on_hitbox_poing_area_entered(area):
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			# On inflige les dégâts de base
			get_parent().infliger_degats(player_id)
			
			# SI Hecker a volé l'ultime de Dallaporta ET qu'il est actif :
			# On inflige une deuxième instance de dégâts pour simuler le bonus temporel
			if extension_active and bonus_degats_temporel > 10.0:
				get_parent().infliger_degats(player_id, false) # false pour ne pas donner double énergie

func utiliser_ultime_vole():
	en_train_dattaquer = true
	var parent = get_parent()
	
	# Consommation d'énergie
	if player_id == 1: parent.energie_p1 = 0
	else: parent.energie_p2 = 0
	parent.mettre_a_jour_ui()

	# --- DÉCLENCHEMENT DU POUVOIR ---
	match ultime_vole:
		"Alexis":
			icone_ultime = preload("res://persos/parade_icon_ultime.png")
			print("Icône Alexis chargée !")
			lancer_pouvoir_alexis_copie()
		"Brillon":
			icone_ultime = preload("res://persos/brillon/logo_ult_bri2.png")
			print("Icône Brillon chargée !")
			lancer_extension_territoire_copie()
		"Garric":
			icone_ultime = preload("res://persos/garric/icon_garric_splash.png")
			print("Icône Garric chargée !")
			lancer_lecon_particuliere_copie()
		"Montaut":
			icone_ultime = preload("res://persos/montaut/icon_descente.png")
			print("Icône Montaut chargée !")
			lancer_descente_gradient_copie()
		"Pouit":
			icone_ultime = preload("res://persos/pouit/icon_ult.png")
			print("Icône Pouit chargée !")
			lancer_ruee_de_becanes_copie()
		"Dallaporta":
			icone_ultime = preload("res://persos/dallaporta/splash_iconv2.png")
			print("Icône Dallaporta chargée !")
			lancer_extension_temporelle_copie()
			
			

	# Reset après usage
	ultime_vole = null
	icone_ultime = icone_origine
	parent.mettre_a_jour_ui()
	en_train_dattaquer = false

func lancer_pouvoir_alexis_copie():
	en_train_dattaquer = true # Bloque le mouvement
	sprite.stop()
	var parent = get_parent()
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	
	# Musique
	get_tree().create_timer(2.0).timeout.connect(func():
		if not audio_s.get_parent():
			add_child(audio_s)
		audio_s.stream = ost_ultime
		audio_s.volume_db = -5
		parent.stopper_tous_les_sons_ultime()
		audio_s.play()
	)
		
	# A. Vidage progressif de la barre (20 secondes)
	var tw_barre = create_tween()
	if player_id == 1:
		tw_barre.tween_property(parent, "energie_p1", 0.0, 20.0)
	else:
		tw_barre.tween_property(parent, "energie_p2", 0.0, 20.0)
	
	# B. Splash Art
	parent.afficher_splashart_ulti(player_id, splash_alexis)
	
	# C. Zoom et centrage (0.4s d'attente pour le style)
	await get_tree().create_timer(0.4).timeout
	parent.zoom_cinematique(self)
	
	# D. Lancement de l'Animation de Danse
	# !! Vérifie que ton animation s'appelle exactement "pose_ultime" !!
	if anim_player.has_animation("pose_ultime"):
		print("coucou oui je lai")
		anim_player.play("pose_ultime")
		await anim_player.animation_finished 
	sprite.scale = Vector2(15, 15)
	# E. Fin de cinématique
	parent.reset_camera()
	
	# F. Activation du bonus de parade
	en_parade = true
	sprite.modulate = Color(1.5, 0.5, 2.0, 1.0) # Effet aura violette
	en_train_dattaquer = false # On libère Alexis
	
	# Timer de fin d'effet
	get_tree().create_timer(20.0).timeout.connect(_on_fin_ultime)


func _on_fin_ultime():
	en_parade = false
	sprite.modulate = Color(1, 1, 1, 1) # Retour couleur normale


func lancer_extension_territoire_copie():
	en_train_dattaquer = true
	var parent = get_parent()
	
	# A. On lance le Splash Art de Brillon (true = déclenche l'extension)
	parent.afficher_splashart_ulti(player_id, splash_brillon, true) 
	
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
		
	# B. Attente de la brisure d'écran (coordonné avec le Splash Art)
	await get_tree().create_timer(2.2).timeout 
	
	if not audio_s.get_parent(): 
		add_child(audio_s)
	audio_s.stream = ost_ultime # Ou un son de Brillon
	audio_s.play()
	
	# C. On libère Hecker
	en_train_dattaquer = false
	
	# D. RESET : On nettoie le sort volé pour pouvoir revoler plus tard
	ultime_vole = null
	icone_ultime = icone_origine
	parent.mettre_a_jour_ui()
	
func lancer_lecon_particuliere_copie():
	var parent = get_parent()
	
	# Désactive la musique de fond
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	
	# Utilise le Splash Art de GARRIC (car c'est son sort)
	parent.afficher_splashart_ulti(player_id, splash_garric, false)
	
	await get_tree().create_timer(0.4).timeout
	parent.zoom_cinematique(self)
	
	# Musique de l'ultime
	audio_s.stream = ost_ultime
	audio_s.volume_db = -15
	parent.stopper_tous_les_sons_ultime()
	audio_s.play()

	# On attend la fin du Splash Art (2.2s au total depuis l'affichage)
	await get_tree().create_timer(1.8).timeout
	
	var cible = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
	
	# SÉCURITÉ VISIBILITÉ : On force tout le monde à être visible avant le TP
	self.visible = true
	if is_instance_valid(cible):
		cible.visible = true
		
		# --- DÉBUT DE LA LEÇON ---
		cible.peut_bouger = false # On fige l'élève
		cible.velocity = Vector2.ZERO
		self.velocity = Vector2.ZERO
		
		# Téléportation (Hecker se TP derrière l'adversaire)
		var side = 1.0 if cible.get_node("AnimatedSprite2D").flip_h else -1.0
		self.global_position = Vector2(cible.global_position.x + (100.0 * side), 580.0)
		self.z_index = 10
		sprite.flip_h = cible.get_node("AnimatedSprite2D").flip_h
		
		# Effets visuels
		self.modulate = Color(5, 5, 5, 1) 
		cible.modulate = Color(1, 0.8, 0.2, 1)
		
		if cible.has_method("_actualiser_hitbox"):
			cible._actualiser_hitbox()
		
		# Retour caméra pour voir l'action
		parent.reset_camera()
		
		# Durée de la punition
		await get_tree().create_timer(4.0).timeout # Réduit à 4s pour Hecker
		
		# --- FIN DE LA LEÇON ---
		if is_instance_valid(cible):
			cible.peut_bouger = true
			cible.modulate = Color(1, 1, 1, 1)
			parent.infliger_degats(player_id)
			if cible.has_method("_actualiser_hitbox"):
				cible._actualiser_hitbox()
		
		self.modulate = Color(1, 1, 1, 1)
		print("Hecker a fini sa leçon copiée.")
func lancer_descente_gradient_copie():
	var parent = get_parent()
	# Lancement Musique
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	audio_s.stream = ost_ultime
	audio_s.volume_db = -10
	audio_s.play()
	
	
	cible_ultime = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
	
	if is_instance_valid(cible_ultime):
		print("coucou")
		cible_ultime.peut_bouger = false
		est_en_train_d_aspirer = true
		await get_tree().create_timer(1.5).timeout
		est_en_train_d_aspirer = false
		lancer_explosion_gradient_et_execute()
		
	parent.reset_camera()

func lancer_explosion_gradient_et_execute():
	# On s'assure que la cible est toujours là
	if is_instance_valid(cible_ultime):
		var distance = global_position.distance_to(cible_ultime.global_position)
		var parent = get_parent()
		
		# On identifie qui est la victime pour l'UI (si Hecker est p1, la victime est p2)
		var pv_actuels_victime = parent.hp_p2 if player_id == 1 else parent.hp_p1
		
		# CALCUL DU SEUIL (20% des PV Max de la CIBLE, pas de Hecker !)
		var seuil_execute = cible_ultime.hp_max * 0.2 
		
		print("DEBUG HECKER : Distance =", distance, " PV Cible =", pv_actuels_victime, " Seuil =", seuil_execute)

		if pv_actuels_victime <= seuil_execute:
			# --- L'EXÉCUTION ---
			print("HECKER EXECUTE !")
			for i in range(6): # On bombarde de dégâts pour garantir le KO
				parent.infliger_degats(player_id)
		else:
			# --- DÉGÂTS NORMAUX (si l'ennemi est proche) ---
			if distance < 400: # Rayon un peu plus large pour Hecker
				parent.infliger_degats(player_id)
				parent.infliger_degats(player_id)
		
		# Libération de la cible
		cible_ultime.peut_bouger = true
		cible_ultime = null

func lancer_ruee_de_becanes_copie():
	var parent = get_parent()
	
	# Gestion Musique
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	audio_s.stream = ost_ultime
	audio_s.volume_db = -10
	audio_s.play()
	
	# 1. Mise à jour UI (L'énergie est déjà mise à 0 par utiliser_ultime_vole)
	parent.mettre_a_jour_ui()
	
	# 2. Cinématique (On utilise le splash de Pouit pour le style ou celui de Hecker)
	parent.afficher_splashart_ulti(player_id, splash_pouit, false) 
	
	await get_tree().create_timer(2.0).timeout
	
	# 3. Lancement des motos
	var timer_becane = 0.0
	while timer_becane < 10.0:
		spawn_moto_aleatoire()
		var delai = randf_range(0.3, 0.7)
		await get_tree().create_timer(delai).timeout
		timer_becane += delai

func spawn_moto_aleatoire():
	if becane_scene:
		var moto = becane_scene.instantiate()
		
		# --- RÉGLAGE DU SOL ---
		# Remplace 650.0 par la position Y exacte de ton sol dans ton niveau
		var hauteur_sol = 600.0 
		
		# On la fait apparaître à gauche, au niveau du sol
		moto.global_position = Vector2(-200.0, hauteur_sol)
		
		moto.damage_owner = player_id
		get_parent().add_child.call_deferred(moto)

func lancer_extension_temporelle_copie():
	var parent = get_parent()
	en_train_dattaquer = true # Immobilise Hecker pendant l'animation de lancement
	
	# --- ÉTAPE CRUCIALE POUR LE DÉCOR ---
	# On définit explicitement le nom du sort pour que le Gameplay 
	# puisse le lire dans 2 secondes lors de l'activation du décor.
	self.ultime_vole = "Dallaporta" 
	
	# 1. On prévient le Gameplay des variables de base
	parent.extension_active = true
	parent.territory_owner = player_id
	parent.type_extension_actuelle = "Dallaporta" 
	
	# 2. Activation de la logique interne (Chrono et Bonus)
	self.extension_active = true 
	self.temps_restant_extension = 30.0
	
	# 3. Gestion Audio
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	parent.stopper_tous_les_sons_ultime()
	
	audio_s.stream = ost_ultime
	audio_s.volume_db = -5
	audio_s.play()
	
	# 4. Lancement du visuel
	# Le 'true' à la fin déclenche la fonction 'activer_extension' du gameplay
	# juste après que le Splash Art ait fini de s'afficher.
	parent.afficher_splashart_ulti(player_id, splash_dall, true) 
	
	# 5. Effet de ralentissement sur l'adversaire
	var cible = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
	if is_instance_valid(cible):
		cible.SPEED = cible.SPEED * 0.5
		
	# On libère Hecker pour qu'il puisse attaquer pendant son extension
	en_train_dattaquer = false
func fin_extension():
	extension_active = false
	bonus_degats_temporel = 0
	var parent = get_parent()
	parent.stopper_tous_les_sons_ultime()
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(true)
	
	var cible = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
	cible.SPEED = cible.SPEED * 2.0 
	parent.fin_extension_visuelle()

func _gestion_extension_temps_copie(delta):
	temps_restant_extension -= delta
	
	# Bonus dégâts de Dallaporta (optionnel si tu veux que Hecker tape plus fort aussi)
	bonus_degats_temporel = (30.0 - temps_restant_extension) * 3.0
	
	if temps_restant_extension <= 0:
		temps_restant_extension = 0
		fin_extension() # Appelle ta fonction qui reset tout

func gerer_dash(delta):
	# On décrémente le timer de cooldown
	if dash_timer > 0:
		dash_timer -= delta
	
	# Détection de l'input selon l'ID du joueur
	var action = "dash_p1" if player_id == 1 else "dash_p2"
	
	if Input.is_action_just_pressed(action) and dash_timer <= 0 and peut_bouger:
		lancer_dash()

func lancer_dash():
	dash_timer = dash_cooldown
	en_dash = true
	AudioManager.play("dash", global_position)
	# On détermine la direction (basée sur le flip_h du sprite)
	var direction = -1 if $AnimatedSprite2D.flip_h else 1
	
	# On applique la vitesse de dash
	velocity.x = direction * vitesse_dash
	
	# Petit effet visuel : on peut changer la couleur ou l'opacité
	modulate.a = 0.5
	
	# On arrête le dash après duree_dash secondes
	await get_tree().create_timer(duree_dash).timeout
	en_dash = false
	modulate.a = 1.0
