extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 500.0 
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var hp_max = 1350
var player_id = 1 
var en_train_dattaquer = false

# --- ÉTATS & PASSIF ---
var peut_bouger = true 
var en_parade = false 
var en_blocage = false
var combo_passif = 0 
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0  
var duree_dash : float = 0.15      

# --- ASSETS ---
@export var projectile_scene : PackedScene = preload("res://script_persos/projectile.tscn")
@export var becane_scene : PackedScene = preload("res://script_persos/becane_objet.tscn") # À charger avec ton fichier moto.tscn
var splash_ultime = preload("res://persos/pouit/splash_ultv2.png")
var icone_ultime = preload("res://persos/pouit/icon_ult.png")
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Ost du Donjon d’Automne.mp3")
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer

func _ready():
	if not audio_s.get_parent(): add_child(audio_s)
	appliquer_cote_initial()

func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_hitbox()

func _actualiser_hitbox():
	if has_node("HitboxPoing"):
		# On ajuste la position du poing selon la direction
		$HitboxPoing.position.x = -850 if sprite.flip_h else 150

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
	var territory_active = gameplay.extension_active and gameplay.territory_owner != player_id
	var action_parade = "blocage_" + str(player_id)

	if not peut_bouger:
		velocity.x = 0
		sprite.play("stay")
		move_and_slide()
		return 

	# 1. On gère le timer et l'input du dash
	gerer_dash(delta)

	# Gestion du blocage
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1)
	else:
		if Input.is_action_pressed(action_parade) and is_on_floor():
			velocity.x = 0
			en_blocage = true
			sprite.modulate = Color(0.5, 0.5, 0.5, 1)
		else:
			en_blocage = false
			sprite.modulate = Color(1, 1, 1, 1)

	# 2. On bloque les inputs normaux si on est en dash
	if not en_dash:
		# Inputs de mouvement
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)

		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			velocity.y = JUMP_VELOCITY

		if Input.is_action_just_pressed(action_attaque) and not en_train_dattaquer:
			frapper()

		if Input.is_action_just_pressed(action_ultime):
			lancer_ruee_de_becanes()

		var direction = Input.get_axis(move_left, move_right)
		if direction != 0 and not en_blocage:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			_actualiser_hitbox()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Gestion des animations
		if not en_train_dattaquer:
			if not is_on_floor():
				sprite.play("jump") 
			elif direction != 0:
				sprite.play("walk")
			else:
				sprite.play("stay")

	move_and_slide()

func frapper():
	en_train_dattaquer = true
	anim_player.play("attaque")
	await anim_player.animation_finished
	en_train_dattaquer = false

# --- CETTE FONCTION GÈRE LE POING ---
func _on_hitbox_poing_area_entered(area):
	print("POUIT TOUCHE : ", area.name)
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			get_parent().infliger_degats(player_id)
			combo_passif += 1
			if combo_passif >= 5:
				lancer_salve_projectiles(cible)
				combo_passif = 0

func lancer_salve_projectiles(cible):
	for i in range(5):
		if projectile_scene:
			var p = projectile_scene.instantiate()
			p.global_position = $HitboxPoing.global_position
			p.target = cible
			p.owner_id = player_id # On transmet l'ID au projectile
			get_parent().add_child.call_deferred(p)
			await get_tree().create_timer(0.2).timeout

func lancer_ruee_de_becanes():
	var parent = get_parent()
	var energie = parent.energie_p1 if player_id == 1 else parent.energie_p2
	if energie >= 100:
		if player_id == 1: parent.energie_p1 = 0
		else: parent.energie_p2 = 0
		parent.mettre_a_jour_ui()
		
		# 2. Cinématique
		parent.afficher_splashart_ulti(player_id, splash_ultime, false)
		await get_tree().create_timer(0.4).timeout
		if parent.has_method("gerer_musique_combat"):
			parent.gerer_musique_combat(false)
		audio_s.stream = ost_ultime
		audio_s.volume_db = -15
		parent.stopper_tous_les_sons_ultime()
		audio_s.play()
		await get_tree().create_timer(2.0).timeout
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

func set_player_id(id):
	player_id = id
	if not is_node_ready(): await ready
	appliquer_cote_initial()

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
