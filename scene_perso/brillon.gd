extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 600.0
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var combo_count = 0 
var en_dash = false 
const DASH_FORCE = 2500.0 
var hp_max = 1050
var player_id = 1 
const DASH_SPEED = 2000.0 
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash_c : bool = false
var vitesse_dash : float = 2000.0  # Ajustez selon la puissance voulue
var duree_dash : float = 0.15      # Temps pendant lequel le perso fonce

# --- ÉTATS ---
var peut_bouger = false 
var en_train_dattaquer = false
var en_parade = false 
var en_blocage = false
var timer_blocage = 0.0

# --- ASSETS ---
var icone_ultime = preload("res://persos/brillon/logo_ult_bri2.png")
var splash_ultime = preload("res://persos/brillon/splash_brillonv1.png") # À remplacer par le tien
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Stormgate Overture.mp3")

# --- RÉFÉRENCES ---
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var label_combo = $%label_combo
func _ready():
	if not audio_s.get_parent():
		add_child(audio_s)
	appliquer_cote_initial()

func appliquer_cote_initial():
	if player_id == 2:
		sprite.flip_h = true
		$HitboxPoing.position.x = -980
	else:
		sprite.flip_h = false
		$HitboxPoing.position.x = 80

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	var gameplay = get_parent()
	# ON VÉRIFIE SI L'ADVERSAIRE A LANCÉ SON TERRITOIRE
	var adverse_id = 2 if player_id == 1 else 1
	var territory_active = (
	gameplay.extension_active and 
	gameplay.territory_owner != player_id and 
	gameplay.type_extension_actuelle == "Brillon")
	
	var action_parade = "blocage_" + str(player_id)
	
	# --- 1. GESTION DU BLOCAGE (Interdit sous Ultime adverse) ---
	if territory_active:
		en_blocage = false # On force l'arrêt du blocage
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
				sprite.modulate = Color(0.1, 0.1, 0.1, 0.5)
		else:
			en_blocage = false
			timer_blocage = 0.0
			if not en_parade: sprite.modulate = Color(1, 1, 1, 1)
	
	if (Input.is_action_pressed(action_parade) and not territory_active) or en_dash:
		move_and_slide()
		return

	if not peut_bouger or en_train_dattaquer:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		move_and_slide()
		return 
	gerer_dash(delta)
	
	if not en_dash_c:
		# --- 2. INPUTS AVEC INVERSION ---
		var move_left = "gauche_" + str(player_id)
		var move_right = "droite_" + str(player_id)
		var move_jump = "saut_" + str(player_id)
		var action_attaque = "attaque_" + str(player_id)
		var action_ultime = "ultime_" + str(player_id)
		
		# Lancement Ultime
		if Input.is_action_just_pressed(action_ultime) and is_on_floor():
			var energie = gameplay.energie_p1 if player_id == 1 else gameplay.energie_p2
			if energie >= 100:
				lancer_extension_territoire()

		if Input.is_action_just_pressed(action_attaque):
			frapper()

		# SAUT (Inversion : Projection arrière)
		if Input.is_action_just_pressed(move_jump) and is_on_floor():
			if territory_active:
				velocity.y = JUMP_VELOCITY * 0.8 # Saute moins haut
				var recul = 1000.0 if not sprite.flip_h else -1000.0
				velocity.x = -recul # Projeté en arrière
			else:
				velocity.y = JUMP_VELOCITY

		# DÉPLACEMENT (Inversion)
		var direction = Input.get_axis(move_left, move_right)
		if territory_active:
			direction = -direction # GAUCHE devient DROITE
		
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			$HitboxPoing.position.x = -980 if sprite.flip_h else 80
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Animations
		if not is_on_floor():
			sprite.play("jump") 
		elif direction != 0:
			sprite.play("walk")
		else:
			sprite.play("stay")

	move_and_slide()

# --- ACTIONS SPÉCIALES ---

func lancer_extension_territoire():
	en_train_dattaquer = true
	var parent = get_parent()
	
	# ON LANCE SEULEMENT LE SPLASH ART (qui lancera l'extension tout seul à la fin)
	parent.afficher_splashart_ulti(player_id, splash_ultime)
	
	if parent.has_method("gerer_musique_combat"):
		parent.gerer_musique_combat(false)
		
	# Musique avec délai (pour coller à la brisure)
	await get_tree().create_timer(2.2).timeout # On attend la fin du splash art
	if not audio_s.get_parent(): add_child(audio_s)
	audio_s.stream = ost_ultime
	audio_s.play()
	
	# Vidage de barre
	var tw = create_tween()
	var prop = "energie_p1" if player_id == 1 else "energie_p2"
	tw.tween_property(parent, prop, 0.0, 30.0)
	
	# On débloque le perso un peu après la brisure
	await get_tree().create_timer(1.0).timeout 
	en_train_dattaquer = false

func frapper():
	en_train_dattaquer = true
	combo_count += 1
	afficher_indicateur_combo()
	if combo_count == 3:
		combo_count = 0
		executer_dash_attaque()
	else:
		anim_player.play("attaque")
		await anim_player.animation_finished
		en_train_dattaquer = false

func executer_dash_attaque():
	en_dash = true
	# On désactive la collision du CORPS (pour passer à travers)
	set_collision_mask_value(1, false) 
	
	# --- FORCE LA HITBOX À RESTER ACTIVE ---
	$HitboxPoing/CollisionShape2D.disabled = false 
	
	var dir = -1.0 if sprite.flip_h else 1.0
	velocity.x = dir * DASH_SPEED
	
	# On crée l'effet de traînée
	for i in range(5):
		creer_fantome()
		await get_tree().create_timer(0.03).timeout
	
	await get_tree().create_timer(0.05).timeout
	
	# Reset
	set_collision_mask_value(1, true)
	velocity.x = 0
	en_dash = false
	en_train_dattaquer = false

func creer_fantome():
	var ghost = Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.global_position = global_position
	ghost.scale = sprite.scale
	ghost.flip_h = sprite.flip_h
	ghost.modulate = Color(0.5, 0.7, 1.0, 0.6)
	ghost.set_script(load("res://script_persos/ghost_effect.gd")) 
	get_parent().add_child(ghost)

func set_player_id(id):
	player_id = id
	if not is_node_ready(): await ready
	appliquer_cote_initial()

func _on_hitbox_poing_area_entered(area):
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			# On inflige les dégâts
			get_parent().infliger_degats(player_id)
			
			# --- LA CORRECTION EST ICI ---
			# Si on est en train de dasher, on coupe la hitbox tout de suite 
			# pour ne pas frapper 50 fois pendant la traversée
			if en_dash:
				$HitboxPoing/CollisionShape2D.set_deferred("disabled", true)
				print("Coup de dash réussi, hitbox désactivée pour le reste du trajet")
func afficher_indicateur_combo():
	# 1. Définir le texte selon le compteur
	if combo_count == 1:
		label_combo.text = "I"
		label_combo.modulate = Color.WHITE
	elif combo_count == 2:
		label_combo.text = "II"
		label_combo.modulate = Color.ORANGE
	elif combo_count == 3:
		label_combo.text = "READY !"
		label_combo.modulate = Color.YELLOW
	
	# 2. Rendre le texte visible et l'animer
	label_combo.visible = true
	label_combo.modulate.a = 1.0 # On reset l'opacité
	
	# Petit effet de "Pop" (Zoom)
	var tw = create_tween().set_parallel(true)
	label_combo.scale = Vector2(1.5, 1.5)
	tw.tween_property(label_combo, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	# 3. Disparition automatique après 0.8 secondes
	# On crée un second tween pour le fondu après un court délai
	var tw_fade = create_tween()
	tw_fade.tween_interval(0.6) # On laisse le texte affiché un peu
	tw_fade.tween_property(label_combo, "modulate:a", 0.0, 0.2) # Fondu sortant
	tw_fade.finished.connect(func(): label_combo.visible = false);


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
	en_dash_c = true
	
	# On détermine la direction (basée sur le flip_h du sprite)
	var direction = -1 if $AnimatedSprite2D.flip_h else 1
	
	# On applique la vitesse de dash
	velocity.x = direction * vitesse_dash
	
	# Petit effet visuel : on peut changer la couleur ou l'opacité
	modulate.a = 0.5
	
	# On arrête le dash après duree_dash secondes
	await get_tree().create_timer(duree_dash).timeout
	en_dash_c = false
	modulate.a = 1.0
