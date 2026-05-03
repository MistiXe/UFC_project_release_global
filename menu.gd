extends Control


@onready var bouton_jouer = %jouer
@onready var anim = $TextureRect/VBoxContainer/jouer/bordure/AnimationPlayer
func _ready() -> void:
	pass


func _on_texture_button_pressed():
	AudioManager.play("clique", global_position)
	# La fonction pour aller à la sélection de champions
	var water = $%WaterTransition
	water.visible = true

	var tw = create_tween()
	# On anime la déformation
	tw.tween_property(water.material, "shader_parameter/progress", 1.0, 0.8).set_trans(Tween.TRANS_SINE)

	await tw.finished
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://script global/champselect.tscn")
	


func _on_label_focus_entered() -> void:
	pass # Replace with function body.

func _on_quit_button_pressed():
	get_tree().quit()

func _on_sound_button_pressed():
	# On récupère l'index du bus "Master" (le bus principal)
	var master_bus = AudioServer.get_bus_index("Master")
	
	# On inverse l'état actuel (si c'est allumé, ça s'éteint, et inversement)
	var is_muted = AudioServer.is_bus_mute(master_bus)
	AudioServer.set_bus_mute(master_bus, !is_muted)
	
	# Optionnel : Changer l'apparence du bouton pour donner un feedback
	if !is_muted:
		$son.texture_normal = load("res://ui_design/20240707dragon9SlicesC.png")
		# Ici tu pourrais changer l'icône du bouton pour une icône "HP barré"
	else:
		print("Son activé")
		$son.texture_normal = load("res://ui_design/20240707dragon9SlicesD.png")

func _on_tutoriel_pressed():
	# On change de scène vers le tuto
	get_tree().change_scene_to_file("res://script global/Tutoriel.tscn")
