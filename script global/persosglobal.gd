extends Node

var choix_p1 = ""
var choix_p2 = ""

var dernier_gagnant_nom : String = ""
var score_final_p1 : int = 0
var score_final_p2 : int = 0

var liste_persos = {
	"hecker": {
		"scene": "res://scene_perso/Hecker.tscn",
		"nom": "Hecker",
		"type": "Attaque",
		"description": "Passif :  Aucun",
		"ultime": "Vol ancestral : \n 
		Malicieux malgré lui, Hecker vole l'ultime d'un personnage aléatoire de l'université \n
		(Certains effets d'extensions du territoire ne sont pas les mêmes que celles du personnage volé)",
		"portrait": "res://persos/hecker_logo.jpg"
	},
	"alexis": {
		"scene": "res://scene_perso/Alexis.tscn",
		"nom" : "Alexis",
		"type": "Defense",
		"description": "Passif :  Aucun",
		"ultime": "Parade Parisienne : \n 
		Alexis change d'état, les dégâts qu'un adversaire inflige sont renvoyé vers lui de 30%",
		"portrait": "res://persos/alexisv1.png"
	},
	"brillon": {
		"scene" : "res://scene_perso/Brillon.tscn",
		"type" : "Attaque",
		"description": "Passif :  Si Brillon réalise 3 attaques, elle obtient un dash",
		"ultime": "Extension du territoire : Absurdité héréditaire \n 
				   Passif de l'extension : Brillon déchaine son courroux et change l'espace qui l'entoure. \n 
				   Les mouvements de l'adversaire sont inversés et la garde est désactivée.",
		"nom": "Brillon",
		"portrait": "res://persos/brillon/splash_brillon.png"
	},
	"garric": {
		"scene" : "res://scene_perso/Garric.tscn",
		"nom": "Garric",
		"type" : "Defense",
		"ultime": "Leçon particulière \n
				   Garric ne perd pas son temps et se colle à son adversaire, tandis que sa cible est stun pendant 3 secondes.",
		
		"description": "Passif :  Si Garric reçoit 3 attaques, il immobilise son adversaire.",
		"portrait": "res://persos/garric/garic_splash.png"
	},
	"montaut": {
		"scene" : "res://scene_perso/Montaut.tscn",
		"nom": "Montaut",
		"type" : "Attaque",
		"description": "Passif :  Toute les 3 secondes, Montaut devient énervé, sa vitesse est augmenté.",
		"ultime": "Descente de gradient \n 
				   En plus d'être énervé, le chef vous balançe un vrai calcul de descente de gradient ! \n 
				   Montaut vous attire et vous inflige des dégâts, plus la cible est loin plus ça fait mal ! \n 
				   Au dessous de 20% d'hp , Montaut vous élimine ! ",
		"portrait": "res://persos/montaut/garric_icon_pp.png"
	},
	"pouit": {
		"scene" : "res://scene_perso/Pouit.tscn",
		"nom": "Pouit",
		"type" : "Attaque",
		"description": "Passif :  Toute les 3 attaques, Pouit envoit une salve de projectiles dévastatrice.",
		"ultime": "Ultime : Démarrage des bécanes  \n 
				  Vous avez allumé vos bécanes ? dit-il d'un air surpris de bon matin à 8h00. \n 
				  Pouit envoit une ruée de bécanes à esquiver pour pas subir son courroux ! ",
		"portrait": "res://persos/pouit/icon_pouit2.png"
	},
	"dallaporta": {
		"scene" : "res://scene_perso/Dallaporta.tscn",
		"type" : "Attaque",
		"description": "Passif :  Dallaporta devient furtif s'il n'est pas touché au bout de 3 secondes",
		"ultime": "Extension du territoire : Retard récursif imminent \n 
				  Que vous soyez en retard ou pas, c'est Dallaporta qui arrivera après vous. \n 
				  Passif de l'extension , vous êtes ralenti à l'infini mais vous pouvez réduire le temps de l'extension en le frappant \n
				  Mais garre à vous ! si vous ne le touchez pas il gagne 5 secondes d'ultime !",
		"nom": "Dallaporta",
		"portrait": "res://persos/dallaporta/dell_icon_v2.png"
	}
}
