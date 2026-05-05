# 🏺 Champollion Fighter

**Champollion Fighter** est un jeu d'action et de combat développé sous **Godot Engine 4**. Le projet explore le mélange entre l'histoire (le déchiffrement des hiéroglyphes) et une mécanique de jeu dynamique, optimisée pour fonctionner aussi bien sur un PC classique que sur une console portable basée sur **Raspberry Pi**.

---

## 📥 Téléchargement et Exécutables

Le jeu est prêt à l'emploi. Il n'est pas nécessaire d'installer Godot pour y jouer. Choisissez simplement la version correspondant à votre système :

### 🖥️ Version Windows
*   **Fichier** : `ChampollionFighter.exe`
*   **Installation** : Téléchargez le dossier complet, extrayez-le et lancez l'exécutable.
*   **Contrôles** : Clavier ou Manette (recommandé).

### 🍓 Version Raspberry Pi (Linux)
Cette version est optimisée pour le matériel ARM.
1.  Transférez le fichier `ChampollionFighter.x86_64` sur votre Raspberry Pi.
2.  Ouvrez un terminal dans le dossier contenant le jeu.
3.  **Donnez les droits d'exécution** au fichier (indispensable sous Linux) :
    ```bash
    chmod +x ChampollionFighter.x86_64
    ```
4.  Lancez le jeu :
    ```bash
    ./ChampollionFighter.x86_64
    ```

---

## 🛠️ Configuration Technique (Raspberry Pi)

Pour garantir la fluidité des animations de fond et des particules sans crash au chargement, la configuration suivante est recommandée :

*   **Rendu graphique** : Mode *Compatibility* (basé sur OpenGL 3.3).
*   **Mémoire GPU** : Minimum **256 Mo**. 
    *   *Note : Si le jeu plante à 100% du chargement, modifiez votre fichier `/boot/config.txt` avec la ligne `gpu_mem=256`.*
*   **Système** : Raspberry Pi OS 64-bit.

---

## ✨ Fonctionnalités clés
*   **Système de combat** : Mécaniques fluides incluant des effets de particules optimisés.
*   **Animations** : Fond animé intégré pour une immersion totale.
*   **Launcher compatible** : Le jeu est conçu pour être lancé via l'interface réseau INUC.

---

## 👤 Crédits
*   **Développement et Programmation** : Alexis et Hodheyfa
*   **Moteur de jeu** : Godot Engine 4.x
*   **Concept** : Action / Aventure historique

---

### 📝 Note pour le jury
Le projet **Champollion Fighter** a nécessité une attention particulière sur l'optimisation des ressources (CPU/GPU) pour permettre un affichage fluide des effets visuels sur des systèmes embarqués limités. Les défis techniques incluaient la gestion du focus de la fenêtre lors du lancement et la compilation des shaders sous Linux ARM.
