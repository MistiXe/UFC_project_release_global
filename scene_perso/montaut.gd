extends CharacterBody2D

# --- VARIABLES DE BASE (Standards du jeu) ---
var SPEED = 700.0
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var hp_max = 100
var player_id = 1 
var ulti_en_cours = false
var est_en_train_d_aspirer = false
var cible_ultime = null
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0  # Ajustez selon la puissance voulue
var duree_dash : float = 0.15      # Temps pendant lequel le perso fonce

# --- ÉTATS ---
var peut_bouger = true 
var en_train_dattaquer = false
var en_parade = false 
var en_blocage = false
var timer_blocage = 0.0
var timer_colere = 0.0
var est_en_colere = false
# --- ASSETS (À remplir plus tard) ---
var ost_ultime = preload("res://song/Sterile Horizon.mp3")

var icone_ultime = preload("res://persos/montaut/icon_descente.png") # On le fera pour l'ultime
var splash_ultime = preload("res://persos/montaut/splash_ult_montautv3.png") # On le fera pour l'ultime
@onready var particules = $ParticulesGradient # Assure-toi que le nom correspond
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_s = AudioStreamPlayer.new()

func _ready():
	if not audio_s.get_parent(): add_child(audio_s)
	appliquer_cote_initial()

func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_hitbox()

func _actualiser_hitbox():
	# Ajuste les positions de tes zones de frappe ici
	if has_node("HitboxPoing"):
		$HitboxPoing.position.x = -980 if sprite.flip_h else 100

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
	var territory_active = (
	gameplay.extension_active and 
	gameplay.territory_owner != player_id and 
	gameplay.type_extension_actuelle == "Brillon")
	var action_parade = "blocage_" + str(player_id)

	# --- 1. VERROU STUN (Ex: Leçon de Garric) ---
	if not peut_bouger:
		velocity.x = 0
		sprite.play("stay")
		move_and_slide()
		return 
	gerer_dash(delta)

	# --- 2. LOGIQUE DE BLOCAGE & TERRITOIRE ---
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1) 
		elif not en_parade and not est_en_colere: # AJOUTE "and not est_en_colere"
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
			# ICI AUSSI : On ne remet en blanc que si on n'est pas en colère
			if not en_parade and not est_en_colere: 
				sprite.modulate = Color(1, 1, 1, 1)

	# --- 3. INPUTS DÉPLACEMENT ---
	if not en_dash:
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)
		
		if Input.is_action_just_pressed(action_ultime):
			utiliser_ultime()
		# SAUT (Avec punition Brillon)
		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			if territory_active:
				velocity.y = JUMP_VELOCITY * 0.8
				var recul = 1000.0 if not sprite.flip_h else -1000.0
				velocity.x = -recul 
			else:
				velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed(action_attaque) and not en_train_dattaquer:
			frapper()

		# DÉPLACEMENT (Inversion territoire)
		var direction = Input.get_axis(move_left, move_right)
		if territory_active:
			direction = -direction 
		
		if direction != 0 and not en_blocage:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			_actualiser_hitbox()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# --- 4. ANIMATIONS ---
		if not en_train_dattaquer:
			if not is_on_floor():
				sprite.play("jump")
			elif direction != 0:
				sprite.play("walk")
			else:
				sprite.play("stay")

	move_and_slide()
	
	# Gestion du cycle de 8 secondes
	timer_colere += delta
	if timer_colere >= 8.0:
		activer_colere()
		timer_colere = 0.0
		
	if est_en_train_d_aspirer and is_instance_valid(cible_ultime):
		var direction_gradient = (global_position - cible_ultime.global_position).normalized()
		var distance = global_position.distance_to(cible_ultime.global_position)
		var force_attraction = clamp(distance * 5.0, 500.0, 3000.0)
		
		cible_ultime.velocity.x = direction_gradient.x * force_attraction
		cible_ultime.move_and_slide()
		
func frapper():
	en_train_dattaquer = true
	
	if anim_player.has_animation("attaque"):
		anim_player.play("attaque")
		AudioManager.play("attaque", global_position)
		await anim_player.animation_finished
	en_train_dattaquer = false

func set_player_id(id):
	player_id = id
	if not is_node_ready(): await ready
	appliquer_cote_initial()

func _on_hitbox_poing_area_entered(area):
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			if est_en_colere:
				# Si en colère, on ignore le blocage adverse !
				get_parent().infliger_degats(player_id)
				# Optionnel : petit effet de stun sur la cible
				if cible.has_method("subir_stun"):
					cible.subir_stun(3.0) 
			else:
				# Attaque normale
				get_parent().infliger_degats(player_id)
func activer_colere():
	est_en_colere = true
	sprite.modulate = Color(2, 0.5, 0.5, 1) # Aura rouge brillante
	
	# La colère dure 2 secondes
	await get_tree().create_timer(2.0).timeout
	
	est_en_colere = false
	sprite.modulate = Color(1, 1, 1, 1) # Retour à la normale


func utiliser_ultime():
	var parent = get_parent()
	var energie = parent.energie_p1 if player_id == 1 else parent.energie_p2
	

	
	if energie >= 100:
		en_train_dattaquer = true
		
		# 1. Consommation d'énergie
		if player_id == 1: parent.energie_p1 = 0
		else: parent.energie_p2 = 0
		parent.mettre_a_jour_ui()
		
		# 2. Cinématique
		parent.afficher_splashart_ulti(player_id, splash_ultime, false)
		await get_tree().create_timer(0.4).timeout
		parent.zoom_cinematique(self)
		if parent.has_method("gerer_musique_combat"):
			parent.gerer_musique_combat(false)
		audio_s.stream = ost_ultime
		audio_s.volume_db = -15
		parent.stopper_tous_les_sons_ultime()
		audio_s.play()
		# 3. Préparation de la cible
		cible_ultime = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
		
		if is_instance_valid(cible_ultime):
			# On fige l'adversaire
			cible_ultime.peut_bouger = false
			est_en_train_d_aspirer = true
			
			# ACTIVATION DES PARTICULES
			# On déplace les particules sur la cible pour qu'elles l'englobent
			particules.global_position = cible_ultime.global_position
			particules.emitting = true
			
			# 4. Phase d'attraction (1.5s)
			await get_tree().create_timer(1.5).timeout
			
			# DESACTIVATION DES PARTICULES
			particules.emitting = false
			
			# 5. Explosion Finale et Exécution
			est_en_train_d_aspirer = false
			lancer_explosion_gradient_et_execute()
			
		parent.reset_camera()
		en_train_dattaquer = false

func lancer_explosion_gradient_et_execute():
	if is_instance_valid(cible_ultime):
		var distance = global_position.distance_to(cible_ultime.global_position)
		var parent = get_parent()
		
		# A. L'Exécution à 20% HP
		# On récupère les PV actuels de la cible
		var pv_cible = parent.hp_p2 if player_id == 1 else parent.hp_p1
		# Calcul du seuil d'exécution (20% de hp_max, qui est 650)
		var seuil_execute = cible_ultime.hp_max * 0.2 # 650 * 0.2 = 130
		
		if pv_cible <= seuil_execute:
			# EXÉCUTION ! On applique des dégâts énormes pour tuer.
			# Tu peux créer une fonction parent.infliger_execute() ou appeler infliger_degats plein de fois.
			# On va faire simple : on inflige 5 fois les dégâts.
			print("EXECUTION !!!")
			for i in range(5):
				parent.infliger_degats(player_id)
		else:
			# B. Dégâts normaux si pas d'exécution
			if distance < 300: # Si l'aspirateur a bien marché
				parent.infliger_degats(player_id) # Dégâts normaux
				parent.infliger_degats(player_id) # Bonus de dégâts ultime
		
		# On libère la cible
		cible_ultime.peut_bouger = true
		cible_ultime = null
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
