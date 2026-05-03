extends Node

# On précharge les sons une seule fois en mémoire
var sons = {
	"dash": preload("res://song/dash.wav"),
	"attaque": preload("res://song/attaquer.wav"),
	"mort": preload("res://song/dead.wav"),
	"lock": preload("res://song/lock_draft.wav"),
	"energie": preload("res://song/energie2.wav"),
	"bloc": preload("res://song/bar_energie.wav"),
	"clique": preload("res://song/clique.wav") 
}

func play(nom_son: String, position: Vector2 = Vector2.ZERO):
	if not sons.has(nom_son): return
	
	var player = AudioStreamPlayer2D.new()
	player.stream = sons[nom_son]
	player.global_position = position
	player.bus = "Master" # S'assure que le bouton Mute fonctionne
	
	add_child(player)
	player.play()
	
	# Se détruit automatiquement quand le son est fini pour libérer la RAM
	player.finished.connect(func(): player.queue_free());
