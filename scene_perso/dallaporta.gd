extends CharacterBody2D

# --- VARIABLES DE BASE ---
var SPEED = 550.0
var JUMP_VELOCITY = -1000
var gravity = 1400.0
var hp_max = 1100
var player_id = 1 
var dash_cooldown : float = 5.0
var dash_timer : float = 0.0
var en_dash : bool = false
var vitesse_dash : float = 2000.0  
var duree_dash : float = 0.15      
var en_train_dattaquer = false

# --- ÉTATS & PASSIF ---
var peut_bouger = true 
var en_blocage = false
var combo_passif = 0 
var dernier_coup_recu_timer = 0.0 # Timer pour l'invisibilité ET le bonus d'ultime
var est_invisible = false
var en_parade = false

# --- VARIABLES ULTIME (EXTENSION TEMPORELLE) ---
var extension_active = false
var temps_restant_extension = 0.0
var bonus_degats_temporel = 0.0 
var icone_ultime = preload("res://persos/dallaporta/splash_iconv2.png") # À assigner dans l'inspecteur ou via preload
var splash_ultime = preload("res://persos/dallaporta/splash_ult_dallv2.png") # À assigner dans l'inspecteur ou via preload
@onready var audio_s = AudioStreamPlayer.new()
var ost_ultime = preload("res://song/Stormgate Overture.mp3")
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer

func _ready():
	# On force la visibilité totale au spawn
	sprite.modulate.a = 1.0
	est_invisible = false
	dernier_coup_recu_timer = 0.0
	if not audio_s.get_parent():
		add_child(audio_s)
	appliquer_cote_initial()
	
func appliquer_cote_initial():
	sprite.flip_h = (player_id == 2)
	_actualiser_hitbox()

func _actualiser_hitbox():
	if has_node("HitboxPoing"):
		$HitboxPoing.position.x = -800 if sprite.flip_h else 150

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# --- GESTION DU PASSIF D'INVISIBILITÉ ---
	dernier_coup_recu_timer += delta
	
	# On ne déclenche l'invisibilité que si on est visible et calme depuis 3s
	if dernier_coup_recu_timer >= 3.0 and not est_invisible:
		_devenir_invisible()

	# --- GESTION DE L'EXTENSION DU TERRITOIRE ---
	if extension_active:
		_gestion_extension_temps(delta)

	if not peut_bouger:
		velocity.x = 0
		sprite.play("stay")
		move_and_slide()
		return 
	gerer_dash(delta)
	
	if not en_dash:
		# --- INPUTS ---
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
			lancer_extension_temporelle()

		var direction = Input.get_axis(move_left, move_right)
		if direction != 0:
			velocity.x = direction * SPEED
			sprite.flip_h = (direction < 0)
			_actualiser_hitbox()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		if not en_train_dattaquer:
			if not is_on_floor(): sprite.play("jump") 
			elif direction != 0: sprite.play("walk")
			else: sprite.play("stay")

	move_and_slide()

func _devenir_invisible():
	if est_invisible or en_train_dattaquer: return
	est_invisible = true
	
	var tween = create_tween()
	# Transition fluide vers l'invisibilité (0.1 d'opacité)
	tween.tween_property(sprite, "modulate:a", 0.1, 1.0) 
	
	# Le perso RESTE invisible tant qu'il n'est pas frappé ou qu'il n'attaque pas.
	# On retire le Timer automatique qui le rendait visible tout seul.

func _revenir_visible():
	if not est_invisible: return
	est_invisible = false
	dernier_coup_recu_timer = 0.0 
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

# --- CORRECTION DE LA HITBOX (DANS DALLAPORTA) ---
func _on_hitbox_poing_area_entered(area):
	if area.name == "HurtBox":
		var cible = area.get_parent()
		if cible != self:
			var degats_totaux = 25.0 + bonus_degats_temporel
			# IMPORTANT : On passe 3 paramètres pour ne pas mélanger dégâts et énergie
			get_parent().infliger_degats(player_id)
			
			combo_passif += 1
			if combo_passif >= 4:
				_appliquer_passif_drain(cible)
				combo_passif = 0

# --- GESTION ULTIME ---
func _gestion_extension_temps(delta):
	# On réduit le temps chaque seconde
	temps_restant_extension -= delta
	
	# Bonus dégâts : +3 par seconde écoulée
	bonus_degats_temporel = (30.0 - temps_restant_extension) * 3.0
	
	# Gain de temps si Dallaporta est tranquille (ton passif)
	if dernier_coup_recu_timer >= 3.0:
		temps_restant_extension += 5.0
		dernier_coup_recu_timer = 0.0
		print("Dallaporta gagne 5s !")

	# FIN DE L'ULTIME
	if temps_restant_extension <= 0:
		temps_restant_extension = 0
		fin_extension() # Cette fonction appelle parent.fin_extension_visuelle()

func frapper():
	# Attaquer brise l'invisibilité
	if est_invisible: 
		_revenir_visible()
	AudioManager.play("attaque", global_position)
	en_train_dattaquer = true
	anim_player.play("attaque")
	await anim_player.animation_finished
	en_train_dattaquer = false


func _appliquer_passif_drain(cible):
	var parent = get_parent()
	if cible.player_id == 1: parent.energie_p1 = clamp(parent.energie_p1 - 5, 0, 100)
	else: parent.energie_p2 = clamp(parent.energie_p2 - 5, 0, 100)
	parent.mettre_a_jour_ui()

func lancer_extension_temporelle():
	var parent = get_parent()
	var energie = parent.energie_p1 if player_id == 1 else parent.energie_p2
	
	if energie >= 100:
		# 1. Reset Energie
		if player_id == 1: parent.energie_p1 = 0
		else: parent.energie_p2 = 0
		
		# 2. On prévient le Gameplay (pour la vidéo et le nom)
		parent.extension_active = true
		parent.territory_owner = player_id
		parent.type_extension_actuelle = "Dallaporta" 
		
		# 3. ON ACTIVE L'EXTENSION INTERNE (C'est ça qui manquait !)
		self.extension_active = true 
		self.temps_restant_extension = 30.0
		
		if parent.has_method("gerer_musique_combat"):
			parent.gerer_musique_combat(false)
		if parent.has_method("gerer_musique_combat"):
			parent.gerer_musique_combat(false)
		parent.stopper_tous_les_sons_ultime()

# On configure et on lance
		audio_s.stream = ost_ultime
		audio_s.volume_db = -5 # Ajuste le volume si besoin
		audio_s.play()
		
		# 4. On lance le visuel
		parent.afficher_splashart_ulti(player_id, splash_ultime, true) 
		
	
		
		# 5. Effet de ralentissement sur l'autre
		var cible = parent.get_node("p2") if player_id == 1 else parent.get_node("p1")
		if is_instance_valid(cible):
			cible.SPEED = cible.SPEED * 0.5

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

# Appelé par Gameplay.gd quand Dallaporta reçoit un coup
func recevoir_coup():
	dernier_coup_recu_timer = 0.0
	if est_invisible:
		_revenir_visible()

func set_player_id(id):
	player_id = id
	if not is_node_ready(): await ready
	appliquer_cote_initial()


# Ajoute cette fonction à la fin de ton script dallaporta.gd
func perdre_temps_ultime(secondes: float):
	if extension_active:
		temps_restant_extension -= secondes
		
		# Feedback visuel pour montrer que le temps s'échappe (optionnel)
		sprite.modulate = Color(1, 0, 0, 1) # Devient rouge brièvement
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)
		
		print("Dallaporta a été touché ! -10 secondes !")
		
		# Si le temps tombe à zéro à cause du coup, l'extension s'arrête au prochain frame
		if temps_restant_extension < 0:
			temps_restant_extension = 0
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
