# Cendres & Cristaux

Prototype de **RPG gacha 2D au tour par tour** (Phase 1), réalisé avec **Godot 4.3**.
Combats 4 contre 4 avec jauge de vitesse, collection de héros, composition
d'équipe, invocations, et un premier chapitre avec boss. Interface en français,
pensée pour le **navigateur** (clavier + souris, lisible sur TV).

## 🎮 Jouer (Web)

Le jeu est déployé automatiquement sur GitHub Pages à chaque mise à jour de `main` :

**https://bodji27200-web.github.io/gacha-/**

Rien à installer : ouvrir le lien dans un navigateur (testé sur Chromium/Edge,
compatible navigateur Xbox). La sauvegarde est locale au navigateur.

> Au premier lancement, une équipe de départ est offerte et la première
> invocation est gratuite. Le son démarre après le premier clic (politique
> d'autoplay des navigateurs).

## Boucle de jeu

Menu → Collection → Équipe (4 héros) → Combats → combat manuel → récompenses
(or, XP, cristaux) → montée de niveau → invocation → boss du chapitre 1.

## Développement local

Pré-requis : **Godot 4.3 stable**.

```bash
# Lancer le jeu
godot --path .

# Construire le cache de classes (1re fois / après ajout de class_name)
godot --headless --import

# Tests headless (185 assertions)
godot --headless res://tests/TestRunner.tscn

# Smoke test d'interface
godot --headless res://tests/UISmoke.tscn
```

## Export Web

```bash
godot --headless --import
godot --headless --export-release "Web" build/web/index.html
```

Génère `index.html`, `index.wasm`, `index.pck`, `index.js`, … Le preset Web
désactive le support des threads (`thread_support=false`) afin d'être compatible
avec GitHub Pages (pas besoin d'en-têtes COOP/COEP). Servir via HTTP (les fichiers
`file://` ne fonctionnent pas) :

```bash
cd build/web && python3 -m http.server 8099   # puis http://localhost:8099
```

## Déploiement

`.github/workflows/deploy.yml` : à chaque push sur `main`, la CI installe
Godot 4.3 + templates, lance les tests, exporte le Web et publie sur GitHub Pages.

## Structure du projet

```
scenes/      Écrans (Boot, MainMenu, StageSelect, TeamBuilder, Collection, Summon, Battle)
src/
  data/      Enums, Stats, HeroInstance, definitions/ (Resources data-driven)
  registry/  Catalogues : héros, compétences, statuts, ennemis, stages, bannières
  autoload/  RNG, DataRegistry, GameState, SaveManager, AudioManager, SceneRouter
  combat/    Moteur de combat pur (CombatEngine, DamageFormula, EnemyAI, …)
  ui/        Style, VisualKit (art procédural), widgets et overlays
assets/fonts/ DejaVu Sans (libre)
tests/       TestRunner + suites + UISmoke
```

## Documentation

- `GAME_DESIGN.md` — vision, formule de combat, héros, économie, invocation.
- `CLAUDE.md` — architecture, conventions, commandes, précautions.
- `ROADMAP.md` — état des systèmes, assets temporaires, phases suivantes.

## Crédits / licences

Projet original (noms, compétences, visuels, histoire). Sprites, portraits et sons
sont **temporaires** (procéduraux). Police : DejaVu Sans (licence libre, voir
`assets/fonts/LICENSE.txt`).
