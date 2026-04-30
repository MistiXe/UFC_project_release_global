extends Area2D

var speed = 1100.0 # Très rapide !
var damage_owner = 1 # Sera défini par Pouit

func _ready():
	# On détruit la moto si elle sort de l'écran après 4 secondes
	await get_tree().create_timer(4.0).timeout
	queue_free()

func _physics_process(delta):
	# La bécane fonce de gauche à droite
	position.x += speed * delta

func _on_area_entered(area):
	if area.name == "HurtBox":
		var victime = area.get_parent()
		if victime.player_id != damage_owner:
			var gameplay = get_parent()
			if gameplay.has_method("infliger_degats"):
				# Le deuxième paramètre 'false' bloque le gain d'énergie
				gameplay.infliger_degats(damage_owner, false)
			
			# On détruit la moto pour ne pas qu'elle touche plusieurs fois
			queue_free()
