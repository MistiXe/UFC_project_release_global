extends Node

var choix_p1 = ""
var choix_p2 = ""

var liste_persos = {
	"hecker": {
		"scene": "res://scene_perso/Hecker.tscn",
		"type": "Attaque",
		"description": "Un hacker rapide qui utilise des glitchs.",
		"stats": "Force: ⭐⭐⭐\nVitesse: ⭐⭐⭐⭐⭐",
		"portrait": "res://persos/hecker_logo.jpg"
	},
	"alexis": {
		"scene": "res://scene_perso/Alexis.tscn",
		"type": "Defense",
		"description": "Un guerrier robuste et flemmard surtout.",
		"stats": "Force: ⭐⭐⭐⭐⭐\nVitesse: ⭐⭐",
		"portrait": "res://persos/alexisv1.png"
	},
	"brillon": {
		"scene" : "res://scene_perso/Brillon.tscn",
		"type" : "Attaque",
		"description": "",
		"stats": "",
		"portrait": "res://persos/brillon/splash_brillon.png"
	},
	"garric": {
		"scene" : "res://scene_perso/Garric.tscn",
		"type" : "Defense",
		"description": "",
		"stats": "",
		"portrait": "res://persos/garric/garic_splash.png"
	},
	"Montaut": {
		"scene" : "",
		"type" : "Attaque",
		"description": "",
		"stats": "",
		"portrait": "res://persos/garric/garic_splash.png"
	},
	"Pouit": {
		"scene" : "",
		"type" : "Attaque",
		"description": "",
		"stats": "",
		"portrait": "res://persos/garric/garic_splash.png"
	}
}
