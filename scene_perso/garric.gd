extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 550.0 
var JUMP_VELOCITY = -900.0
var gravity = 1500.0
var player_id = 1 
var hp_max = 6500
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0  
var duree_dash : float = 0.15      

# --- ÉTATS ---
var peut_bouger = true 
var en_train_dattaquer = false
var ulti_en_cours = false 
var en_blocage = false
var en_parade = false
var passif_en_cours = false

var timer_blocage = 0.0

# --- PASSIF : INERTIE PESANTE ---
var coups_recus = 0
const COUPS_POUR_PASSIF = 4
@onready var audio_s = AudioStreamPlayer.new()

@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer

var icone_ultime = preload("res://persos/garric/icon_garric_splash.png") 
var splash_ultime = preload("res://persos/garric/splash_garricv3.1.png")
var ost_ultime = preload("res://song/Ombres de Shamisen.mp3")
func _ready():
	visible = true
	if not audio_s.get_parent():
		add_child(audio_s)
	appliquer_cote_initial()

func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_position_hitbox()

# --- FONCTION CRUCIALE : PIVOT HITBOX ---
func _actualiser_position_hitbox():
	if has_node("HitboxPoing"):
		# Si Garric regarde à gauche (flip_h vrai), la hitbox va à -680
		# S'il regarde à droite, elle va à 150
		$HitboxPoing.position.x = -680 if sprite.flip_h else 150
	
	# Si tu as aussi une HurtBox (le rectangle bleu de corps)
	# Assure-toi qu'elle reste bien centrée à (0,0) dans l'éditeur

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
	# --- GESTION DU TERRITOIRE DE BRILLON ---
	# On vérifie si l'extension est active et appartient à l'adversaire
	var territory_active = (
	gameplay.extension_active and 
	gameplay.territory_owner != player_id and 
	gameplay.type_extension_actuelle == "Brillon")
	var action_parade = "blocage_" + str(player_id)
	gerer_dash(delta)
	# 1. LOGIQUE DE BLOCAGE (Interdiction sous territoire)
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1) # Flash rouge d'interdiction
		elif not en_parade:
			sprite.modulate = Color(1, 1, 1, 1)
	else:
		# Blocage normal
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

	# Force la hitbox à suivre le regard
	if has_node("HitboxPoing"):
		$HitboxPoing.position.x = -680 if sprite.flip_h else 150
	if not en_dash:
		# --- INPUTS ---
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)

		# 2. SAUT (Inversion sous territoire)
		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			if territory_active:
				velocity.y = JUMP_VELOCITY * 0.8
				var recul = 1000.0 if not sprite.flip_h else -1000.0
				velocity.x = -recul # Projeté en arrière
			else:
				velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed(action_ultime):
			lancer_lecon_particuliere()

		if Input.is_action_just_pressed(action_attaque):
			frapper()

		# 3. DÉPLACEMENT (Inversion sous territoire)
		var direction = Input.get_axis(move_left, move_right)
		if territory_active:
			direction = -direction # GAUCHE devient DROITE
		
		if direction != 0 and peut_bouger:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
		
		# --- 4. GESTION DES ANIMATIONS ---
		if not en_train_dattaquer:
			if not is_on_floor():
				sprite.play("jump")
			elif direction != 0:
				sprite.play("walk")
			else:
				sprite.play("stay")

	move_and_slide()
# --- PASSIF ---
func recevoir_coup_passif(adversaire):
	if passif_en_cours: return
	coups_recus += 1
	if coups_recus >= COUPS_POUR_PASSIF:
		appliquer_lourdeur(adversaire)
		coups_recus = 0

func appliquer_lourdeur(cible):
	if cible == null: return
	passif_en_cours = true
	var v_orig = cible.SPEED
	cible.SPEED *= 0.4
	cible.modulate = Color(0.2, 0.2, 1.0, 1.0)
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(cible):
		cible.SPEED = v_orig
		cible.modulate = Color(1, 1, 1, 1)
	passif_en_cours = false

func lancer_lecon_particuliere():
	var parent = get_parent()
	var energie = parent.energie_p1 if player_id == 1 else parent.energie_p2
	
	# --- ON VÉRIFIE L'ÉNERGIE TOUT DE SUITE ---
	if energie >= 100 and not ulti_en_cours:
		ulti_en_cours = true # Verrouille pour éviter le spam
		
		# 1. Musique et Splash Art (Seulement si on a 100%)
		if parent.has_method("gerer_musique_combat"):
			parent.gerer_musique_combat(false)
		
		parent.afficher_splashart_ulti(player_id, splash_ultime, false)
		
		# 2. Reset Energie
		if player_id == 1: parent.energie_p1 = 0
		else: parent.energie_p2 = 0
		parent.mettre_a_jour_ui()
		
		# 3. Cinématique
		await get_tree().create_timer(0.4).timeout
		parent.zoom_cinematique(self)
		
		audio_s.stream = ost_ultime
		audio_s.volume_db = -15
		parent.stopper_tous_les_sons_ultime()
		audio_s.play()

		# Attente fin splash art
		await get_tree().create_timer(1.8).timeout
		
		var cible = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
		if is_instance_valid(cible):
			cible.visible = true
			cible.peut_bouger = false
			cible.velocity = Vector2.ZERO
			
			# Téléportation
			var side = 1.0 if cible.get_node("AnimatedSprite2D").flip_h else -1.0
			self.global_position = Vector2(cible.global_position.x + (100.0 * side), 580.0)
			self.z_index = 10
			sprite.flip_h = cible.get_node("AnimatedSprite2D").flip_h
			
			# Effets
			self.modulate = Color(5, 5, 5, 1)
			cible.modulate = Color(1, 0.8, 0.2, 1)
			
			if cible.has_method("_actualiser_hitbox"):
				cible._actualiser_hitbox()
			
			# Durée de la punition (7s)
			await get_tree().create_timer(7.0).timeout
			
			# Fin de leçon
			if is_instance_valid(cible):
				cible.peut_bouger = true
				cible.modulate = Color(1, 1, 1, 1)
				parent.infliger_degats(player_id)
				if cible.has_method("_actualiser_hitbox"):
					cible._actualiser_hitbox()
			
			self.modulate = Color(1, 1, 1, 1)
			ulti_en_cours = false # Garric est enfin libéré du verrou
	else:
		print("Pas assez d'énergie pour la leçon !")

func frapper():
	
	en_train_dattaquer = true
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
			get_parent().infliger_degats(player_id)
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
