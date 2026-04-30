extends Area2D

var speed = 950.0
var target = null 
var direction = Vector2.ZERO
var owner_id = 1 # Rempli par Pouit lors du tir

func _ready():
	# On attend une frame pour valider la position de la cible
	await get_tree().process_frame
	
	if is_instance_valid(target):
		# Calcul de la direction horizontale uniquement
		if target.global_position.x > global_position.x:
			direction = Vector2.RIGHT
		else:
			direction = Vector2.LEFT
	
	# Oriente le sprite
	if direction == Vector2.LEFT:
		$Sprite2D.flip_h = true
	
	# Sécurité : détruit le projectile après 3 secondes
	await get_tree().create_timer(3.0).timeout
	queue_free()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_area_entered(area):
	if area.name == "HurtBox":
		var victime = area.get_parent()
		# On vérifie qu'on ne touche pas celui qui a tiré
		if victime.player_id != owner_id:
			var gameplay = get_parent()
			if gameplay.has_method("infliger_degats"):
				gameplay.infliger_degats(owner_id)
			queue_free() # Disparition à l'impact
