extends CharacterBody2D

# --- VARIABLES DE BASE ---
const SPEED = 600.0
const JUMP_VELOCITY = -1000
var gravity = 1400.0

var hp_max = 450
var player_id = 1 

# --- ÉTATS ---
var peut_bouger = false 
var en_train_dattaquer = false
var en_parade = false # Actif pendant les 20s de l'ultime
var en_blocage = false
var timer_blocage = 0.0

# --- ASSETS ---
var icone_ultime = preload("res://parade_icon_ultime.png")
var splash_ultime = preload("res://persos/alexis/splashulti/parade.png")
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Parade Parisienne.mp3")
# --- RÉFÉRENCES ---
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer


# Remplace ton _ready actuel par celui-ci pour éviter les conflits
func _ready():
	if not audio_s.get_parent():
		add_child(audio_s)
	# On appelle l'application du côté immédiatement au cas où l'ID est déjà là
	appliquer_cote_initial()

func appliquer_cote_initial():
	# On définit une distance de frappe fixe (ex: 80 pixels)
	# Tu peux ajuster ce chiffre selon la position de ton poing
	
	
	if player_id == 2:
		sprite.flip_h = true
		# On force la hitbox à GAUCHE
		$HitboxPoing.position.x = -580
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
	
	var gameplay = get_parent()
	# ON VÉRIFIE SI BRIILLON A LANCÉ SON TERRITOIRE
	# Si l'extension est active et que ce n'est pas Alexis qui l'a lancée
	var territory_active = gameplay.extension_active and gameplay.territory_owner != player_id
	
	var action_parade = "blocage_" + str(player_id)
	
	# --- MODIFICATION TERRITOIRE : BLOCAGE INTERDIT ---
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1) # Flash rouge d'interdiction
		elif not en_parade:
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		# Logique de blocage normale
		if Input.is_action_pressed(action_parade) and is_on_floor() and not en_train_dattaquer:
			timer_blocage += delta
			velocity.x = 0
			sprite.modulate = Color(0.5, 0.5, 0.5, 0.5) 
			if timer_blocage >= 0.5:
				en_blocage = true
				sprite.modulate = Color(0.1, 0.1, 0.1, 0.5)
		else:
			en_blocage = false
			timer_blocage = 0.0
			if not en_parade: sprite.modulate = Color(1, 1, 1, 1)

	# Bloquer le mouvement si on maintient la touche (seulement hors territoire)
	if Input.is_action_pressed(action_parade) and not territory_active:
		move_and_slide()
		return
	
	if anim_player.current_animation == "pose_ultime":
		velocity.x = 0
		move_and_slide()
		return

	# 2. ÉTATS BLOQUANTS
	if not peut_bouger or en_train_dattaquer:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 

	# 3. INPUTS
	var move_left = "gauche_" + str(player_id)
	var move_right = "droite_" + str(player_id)
	var move_jump = "saut_" + str(player_id)
	var action_attaque = "attaque_" + str(player_id)
	var action_ultime = "ultime_" + str(player_id)
	
	# 4. Logique de l'Ultime
	if Input.is_action_just_pressed(action_ultime) and not en_parade and is_on_floor():
		var energie = gameplay.energie_p1 if player_id == 1 else gameplay.energie_p2
		if energie >= 100:
			lancer_parade_parisienne()

	# 5. Logique d'Attaque
	if Input.is_action_just_pressed(action_attaque):
		frapper()

	# 6. SAUT (Inversion : Projection arrière si territoire actif)
	if Input.is_action_just_pressed(move_jump) and is_on_floor():
		if territory_active:
			velocity.y = JUMP_VELOCITY * 0.8
			var recul = 1000.0 if not sprite.flip_h else -1000.0
			velocity.x = -recul 
		else:
			velocity.y = JUMP_VELOCITY

	# 7. MOUVEMENT (Inversion Droite/Gauche si territoire actif)
	var direction = Input.get_axis(move_left, move_right)
	if territory_active:
		direction = -direction # GAUCHE devient DROITE
	
	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
		$HitboxPoing.position.x = -580 if sprite.flip_h else 80
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 8. Animations
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

func lancer_parade_parisienne():
	# --- 1. PRÉPARATION ET CINÉMATIQUE ---
	en_train_dattaquer = true # On bloque Alexis
	sprite.stop()
	var parent = get_parent()
	
	# On coupe la musique de fond
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	
	# Affichage du Splash Art au centre
	parent.afficher_splashart_ulti(player_id, splash_ultime)
	
	# Petit temps d'arrêt pour le style avant le zoom
	await get_tree().create_timer(0.4).timeout
	parent.zoom_cinematique(self)
	
	# Lancement de la musique de l'ultime
	if not audio_s.get_parent():
		add_child(audio_s)
	audio_s.stream = ost_ultime
	audio_s.volume_db = -15
	parent.stopper_tous_les_sons_ultime()
	audio_s.play()

	# --- 2. LANCEMENT DE LA DANSE ET DE LA BARRE ---
	if anim_player.has_animation("pose_ultime"):
		anim_player.play("pose_ultime")
		
		# C'EST ICI QUE LE CLIGNOTEMENT DE L'ICÔNE COMMENCE
		# On vide la barre d'énergie sur 20 secondes
		var icone_ui = parent.icon_ulti_p1 if player_id == 1 else parent.icon_ulti_p2
		icone_ui.set_meta("en_cours_d_utilisation", true)
		var tw_barre = create_tween()
		if player_id == 1:
			tw_barre.tween_property(parent, "energie_p1", 0.0, 20.0)
		else:
			tw_barre.tween_property(parent, "energie_p2", 0.0, 20.0)
		
		# On attend que l'animation de pose soit finie pour rendre la main au joueur
		await anim_player.animation_finished 

	# --- 3. RETOUR AU JEU ET BONUS ---
	parent.reset_camera()
	
	en_parade = true # Active la protection
	sprite.modulate = Color(1.5, 0.5, 2.0, 1.0) # Aura violette (Alexis est en mode "Buff")
	
	en_train_dattaquer = false # Alexis peut maintenant bouger et taper en dansant
	print("Alexis est en mode PARADE !")

	# --- 4. FIN DE L'EFFET ---
	# Après 20 secondes, on remet Alexis à la normale
	get_tree().create_timer(20.0).timeout.connect(_on_fin_ultime)

func _on_fin_ultime():
	en_parade = false
	sprite.modulate = Color(1, 1, 1, 1) # Alexis redevient normal
	
	# FORCE l'UI à s'éteindre
	var parent = get_parent()
	if player_id == 1:
		parent.energie_p1 = 0
	else:
		parent.energie_p2 = 0
		
	# On appelle la mise à jour pour que l'UI voit le "0" immédiatement
	parent.mettre_a_jour_ui()
# --- SIGNAUX ET SETUP ---

func set_player_id(id):
	player_id = id
	print("Alexis a reçu son ID : ", id) # Pour vérifier dans la console
	# On attend que le nœud soit prêt pour manipuler le sprite
	if not is_node_ready():
		await ready
	appliquer_cote_initial()

func _on_hitbox_poing_area_entered(area):
	# Si on touche une HurtBox adverse
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			get_parent().infliger_degats(player_id)
