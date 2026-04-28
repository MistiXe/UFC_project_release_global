extends Control


@onready var bouton_jouer = %jouer
@onready var anim = $TextureRect/VBoxContainer/jouer/bordure/AnimationPlayer
func _ready() -> void:
	pass


func _on_texture_button_pressed():
	# La fonction pour aller à la sélection de champions
	%fondusortant.play("fondu")
	get_tree().change_scene_to_file("res://script global/champselect.tscn")
	


func _on_label_focus_entered() -> void:
	pass # Replace with function body.
