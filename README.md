# TrueRP_PortraitElvUI

**TrueRP_PortraitElvUI** est un addon pour World of Warcraft 3.3.5 qui remplace dynamiquement les portraits d'ElvUI (joueur, cible, groupe, familier) par des textures personnalisées issues du système TrueRP.

## 🛑 ATTENTION

Pensez à activer l'option "portrait 2D" pour les cadres d'unités comme le joueur, la cible, le familier et les membres du groupes, sinon l'addon est sans effet pour les cadres non paramétrés de la sorte !

## ✨ Fonctionnalités

- Remplacement du portrait 2D de :
  - Joueur
  - Cible (si elle a l’addon)
  - Groupe (si les membres ont l’addon)
  - Familier (le vôtre ou celui d’un autre joueur si défini)
- Communication automatique des portraits avec les autres joueurs du groupe via `SendAddonMessage`
- Lecture centralisée dans la base `TrueRP_DB`
- Utilisation des portraits définis via **TrueRP_PortraitSelector**

## 🔧 Installation

1. Copiez le dossier `TrueRP_PortraitElvUI` dans `Interface/AddOns/`
2. Installez également :
   - [TrueRP_DB](https://github.com/matthieuAlbertelli/TrueRP_DB)
   - [TrueRP_PortraitSelector](https://github.com/matthieuAlbertelli/TrueRP_PortraitSelector)
3. Connectez-vous et profitez de vos portraits personnalisés dans ElvUI !

## 📂 Architecture

- `core.lua` : initialisation, hooking ElvUI
- `events.lua` : écoute des événements
- `network.lua` : gestion des AddonMessages
- `frames.lua` : création/remplacement des textures
- `utils.lua` : fonctions utilitaires
- `config.lua` : options éventuelles (future extension)

## 📄 Licence

Distribué sous la licence MIT. Voir [LICENSE](./LICENSE) pour plus de détails.

---

Fait partie de la suite d’addons [TrueRP DB](https://github.com/matthieuAlbertelli/TrueRP_DB) et [TrueRP Portrait Selector](https://github.com/matthieuAlbertelli/TrueRP_PortraitSelector)
