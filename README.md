# 🎮 Projet INUC : Le Launcher de Jeux

Bienvenue dans le projet **INUC**, une interface de gestion et de lancement de jeux conçue spécifiquement pour Raspberry Pi et Windows. Ce projet permet de naviguer dans une bibliothèque de jeux, de les installer via un serveur distant et de les lancer directement depuis une interface optimisée pour la manette.

## 🚀 Caractéristiques
*   **Interface Intuitive** : Développée avec Godot Engine 4.
*   **Système d'Installation** : Téléchargement automatique des jeux depuis un serveur vers le stockage local.
*   **Cross-Platform** : Compatible avec Windows et Linux (Raspberry Pi).
*   **Gestion Réseau** : Configuration du Wi-Fi intégrée et Dashboard de contrôle.

---

## 📥 Installation et Jeu

Pour jouer au jeu, vous devez installer l'exécutable correspondant à votre système d'exploitation.

### 🖥️ Pour Windows
1. Téléchargez le dossier compressé `.zip` de la version Windows.
2. Extrayez le contenu dans le dossier de votre choix.
3. Lancez l'exécutable `InucInterface.exe`.

### 🍓 Pour Raspberry Pi (Linux)
1. Transférez l'exécutable Linux sur votre Raspberry Pi (via `scp` ou clé USB).
2. Ouvrez un terminal dans le dossier du jeu.
3. Donnez les permissions d'exécution au fichier :
   ```bash
   chmod +x InucInterface.x86_64
