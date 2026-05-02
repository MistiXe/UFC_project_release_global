extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 600.0
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var hp_max = 100
var player_id = 1 
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0 
var duree_dash : float = 0.15      

# --- ÉTATS ---
var peut_bouger = false 
var en_train_dattaquer = false
var en_parade = false # Le buff de l'ultime
var en_blocage = false
var timer_blocage = 0.0

# --- ASSETS ---
var icone_ultime = preload("res://persos/parade_icon_ultime.png")
var splash_ultime = preload("res://persos/alexis/splashulti/parade.png")
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Parade Parisienne.mp3")

# --- RÉFÉRENCES ---
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer

func _ready():
	if not audio_s.get_parent():
		add_child(audio_s)
	appliquer_cote_initial()

func _actualiser_hitbox():
	if has_node("HitboxPoing"):
		$HitboxPoing.position.x = -750 if sprite.flip_h else 80
		
func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_hitbox()

func _physics_process(delta):
	# 1. Gravité
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
	# Vérification du territoire adverse (Brillon)
	var territory_active = (
		gameplay.extension_active and 
		gameplay.territory_owner != player_id and 
		gameplay.type_extension_actuelle == "Brillon" # <--- IMPORTANT : On précise Brillon ici
	)
	var action_parade = "blocage_" + str(player_id)
	
	if not peut_bouger:
		velocity.x = 0
		sprite.play("stay")
		# FIX : On force la hitbox à se remettre sur le corps
		_actualiser_hitbox()
		move_and_slide()
		return
	gerer_dash(delta)
	# --- LOGIQUE DE BLOCAGE ---
	if territory_active:
		en_blocage = false
		if Input.is_action_pressed(action_parade):
			sprite.modulate = Color(1, 0, 0, 1) # Flash rouge d'interdiction
		elif not en_parade:
			sprite.modulate = Color(1, 1, 1, 1)
	else:
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

	# Bloquer mouvement si on maintient la touche (hors territoire)
	if Input.is_action_pressed(action_parade) and not territory_active:
		move_and_slide()
		return
	
	# Pause pour pose ultime
	if anim_player.current_animation == "pose_ultime":
		velocity.x = 0
		move_and_slide()
		return

	# États bloquants
	if en_train_dattaquer:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 
	if not en_dash:
		# --- INPUTS ---
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)
		
		# 4. Lancement Parade Parisienne
		if Input.is_action_just_pressed(action_ultime) and not en_parade and is_on_floor():
			var energie = gameplay.energie_p1 if player_id == 1 else gameplay.energie_p2
			if energie >= 100:
				lancer_parade_parisienne()

		# 5. Attaque
		if Input.is_action_just_pressed(action_attaque):
			frapper()

		# 6. Saut (Inversion si territoire actif)
		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			if territory_active:
				velocity.y = JUMP_VELOCITY * 0.8
				var recul = 1000.0 if not sprite.flip_h else -1000.0
				velocity.x = -recul 
			else:
				velocity.y = JUMP_VELOCITY

		# 7. Mouvement (Inversion si territoire actif)
		var direction = Input.get_axis(move_left, move_right)
		if territory_active:
			direction = -direction 
		
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			# Ajustement Hitbox selon direction
			_actualiser_hitbox()
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
	anim_player.play("attaque")
	await anim_player.animation_finished
	en_train_dattaquer = false

func lancer_parade_parisienne():
	en_train_dattaquer = true 
	sprite.stop()
	var parent = get_parent()
	
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
	
	parent.afficher_splashart_ulti(player_id, splash_ultime, false)
	
	await get_tree().create_timer(0.4).timeout
	parent.zoom_cinematique(self)
	
	audio_s.stream = ost_ultime
	audio_s.volume_db = -15
	parent.stopper_tous_les_sons_ultime()
	audio_s.play()

	if anim_player.has_animation("pose_ultime"):
		anim_player.play("pose_ultime")
		
		var icone_ui = parent.icon_ulti_p1 if player_id == 1 else parent.icon_ulti_p2
		icone_ui.set_meta("en_cours_d_utilisation", true)
		
		var tw_barre = create_tween()
		if player_id == 1:
			tw_barre.tween_property(parent, "energie_p1", 0.0, 20.0)
		else:
			tw_barre.tween_property(parent, "energie_p2", 0.0, 20.0)
		
		await anim_player.animation_finished 
	
	
	parent.reset_camera()
	en_parade = true 
	sprite.modulate = Color(1.5, 0.5, 2.0, 1.0) # Aura violette
	en_train_dattaquer = false 
	
	get_tree().create_timer(20.0).timeout.connect(_on_fin_ultime)

func _on_fin_ultime():
	en_parade = false
	sprite.modulate = Color(1, 1, 1, 1) 
	var parent = get_parent()
	if player_id == 1: parent.energie_p1 = 0
	else: parent.energie_p2 = 0
	parent.mettre_a_jour_ui()

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
