extends CharacterBody2D

# --- VARIABLES DE BASE ---
const SPEED = 700.0
const JUMP_VELOCITY = -1000
var gravity = 1400.0

var hp_max = 650
var player_id = 1 

# --- ÉTATS ---
var peut_bouger = false 
var en_train_dattaquer = false
var en_parade = false # Actif pendant les 20s de l'ultime
var en_blocage = false
var timer_blocage = 0.0
# --- ASSETS ---
var icone_ultime = preload("res://persos/hecker/assets_hecker/Vol ancestral.png")
var splash_ultime = preload("res://persos/hecker/splash_hecker_.png")
var splash_alexis = preload("res://persos/alexis/splashulti/parade.png")
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Voleur de Sorts_hecker_theme.mp3")
# --- RÉFÉRENCES ---
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
var liste_personnages = ["Alexis", "Hecker"]

### Setup ultime

var ultime_vole = null          # Stocke le nom de la fonction à appeler
var icone_origine = preload("res://persos/hecker/assets_hecker/Vol ancestral.png") # Ton icône de base


func _ready():
	if not audio_s.get_parent():
		add_child(audio_s)
	# On appelle l'application du côté immédiatement au cas où l'ID est déjà là
	appliquer_cote_initial()

func appliquer_cote_initial():
	if player_id == 2:
		sprite.flip_h = true
		# On force la hitbox à GAUCHE
		$HitboxPoing.position.x = -1080
		print("Hitbox placée à gauche pour J2")
	else:
		sprite.flip_h = false
		# On force la hitbox à DROITE
		$HitboxPoing.position.x = 80
		print("Hitbox placée à droite pour J1")

func _physics_process(delta):
	# 1. Gestion de la gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var action_parade = "blocage_" + str(player_id) # Touche 3 ou KP 3
	
	if Input.is_action_pressed(action_parade) and is_on_floor() and not en_train_dattaquer:
		timer_blocage += delta
		velocity.x = 0 # Immobilisé pendant qu'il se prépare
		
		# Feedback visuel : devient de plus en plus sombre/gris en chargeant
		sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) 
		
		if timer_blocage >= 0.5:
			en_blocage = true
			sprite.modulate = Color(0.1, 0.1, 0.1, 0.5) # Noir/Gris acier quand le blocage est actif
	else:
		# Reset quand on relâche
		en_blocage = false
		timer_blocage = 0.0
		if not en_parade: # Si on n'est pas non plus dans l'ultime d'Alexis
			sprite.modulate = Color(1, 1, 1, 1)

	# Bloquer le mouvement si on maintient la touche
	if Input.is_action_pressed(action_parade):
		move_and_slide()
		return
	if anim_player.current_animation == "ultime_hecker":
		velocity.x = 0
		move_and_slide()
		return

	# 2. BLOCAGE : Si on fait l'Ulti ou une attaque
	if not peut_bouger or en_train_dattaquer:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 

	# 3. Tes Inputs (ON GARDE TOUT ICI)
	var move_left = "gauche_" + str(player_id)
	var move_right = "droite_" + str(player_id)
	var move_jump = "saut_" + str(player_id)
	var action_attaque = "attaque_" + str(player_id)
	var action_ultime = "ultime_" + str(player_id)
	
	# 4. Logique de l'Ultime
	if Input.is_action_just_pressed(action_ultime) and not en_train_dattaquer and is_on_floor():
		var energie = get_parent().energie_p1 if player_id == 1 else get_parent().energie_p2
		if energie >= 100:
			# SI on n'a rien volé : on vole
			if ultime_vole == null:
				phase_vol_ancestral()
			# SI on a déjà quelque chose : on l'utilise !
			else:
				utiliser_ultime_vole()

	if Input.is_action_just_pressed(action_attaque):
		frapper() 

	# 6. Mouvement standard
	if Input.is_action_just_pressed(move_jump) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction = Input.get_axis(move_left, move_right)
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
		
		# On définit la même distance que dans appliquer_cote_initial
		if sprite.flip_h: # Si regarde à gauche
			$HitboxPoing.position.x = -1080
		else: # Si regarde à droite
			$HitboxPoing.position.x = 80
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 7. Animations de base
	if not is_on_floor():
		sprite.play("jump") 
	elif direction != 0:
		sprite.play("walk")
	else:
		sprite.play("stay")

	move_and_slide()

# --- ACTIONS SPÉCIALES ---

func frapper():
	en_train_dattaquer = true
	anim_player.play("attaque") # Joue l'anim d'attaque classique
	await anim_player.animation_finished
	en_train_dattaquer = false

func phase_vol_ancestral():
	en_train_dattaquer = true
	sprite.stop()
	var parent = get_parent()
	
	# A. Mise en scène
	parent.afficher_splashart_ulti(player_id, splash_ultime)
	await get_tree().create_timer(0.2).timeout
	parent.zoom_cinematique(self)
	
	if anim_player.has_animation("ultime_hecker"):
		anim_player.play("ultime_hecker")
		await anim_player.animation_finished
	
	# --- B. LE TIRAGE ALÉATOIRE ---
	var choix_possibles = liste_personnages.duplicate()
	choix_possibles.erase("Hecker") # On s'enlève de la liste pour ne pas se voler soi-même
	
	# On pioche un nom au hasard
	ultime_vole = choix_possibles[randi() % choix_possibles.size()]
	
	# C. On change l'icône selon le résultat
	# Il faut que tu aies tes icônes prêtes dans tes dossiers
	if ultime_vole == "Alexis":
		icone_ultime = preload("res://parade_icon_ultime.png")
	elif ultime_vole == "Voleur":
		# icone_ultime = preload("res://...png")
		pass
		
	print("HECKER a généré l'ultime de : ", ultime_vole)
	parent.mettre_a_jour_ui() # On prévient l'interface

	# D. Reset (IMPORTANT : Correction du Scale encore !)
	
	parent.reset_camera()
	en_train_dattaquer = false

# --- SIGNAUX ET SETUP ---

func set_player_id(id):
	player_id = id
	print("Hecker a reçu son ID : ", id) # Pour vérifier dans la console
	# On attend que le nœud soit prêt pour manipuler le sprite
	if not is_node_ready():
		await ready
	appliquer_cote_initial()

func _on_hitbox_poing_area_entered(area):
	# Si on touche une HurtBox adverse
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			print("coucou je te tape")
			get_parent().infliger_degats(player_id)


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
			icone_ultime = preload("res://parade_icon_ultime.png")
			print("Icône Alexis chargée !")
			lancer_pouvoir_alexis_copie()
		"Samurai":
			# lancer_pouvoir_samurai_copie()
			pass
		"Voleur":
			# lancer_pouvoir_voleur_copie()
			pass

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
