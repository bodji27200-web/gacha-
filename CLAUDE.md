# CLAUDE.md — Guide du dépôt

Projet : **Cendres & Cristaux**, prototype de RPG gacha 2D au tour par tour
(Godot 4.3, export Web). Tous les textes joueur sont en **français**.

## Version Godot

**Godot 4.3 stable exactement** — binaire local, templates d'export et CI doivent
rester sur 4.3 pour éviter tout décalage. La cible finale est l'**export Web**
(GitHub Pages), pas un exécutable PC.

## Architecture

Data-driven : les définitions immuables sont séparées des données joueur et de la
logique. La logique de combat est pure (sans dépendance à la scène) et testable
en headless.

```
project.godot            Autoloads, rendu gl_compatibility, fenêtre responsive
export_presets.cfg       Preset "Web" (thread_support=false → compatible Pages)
icon.svg
scenes/                  Scènes pilotées par script (Control + .gd)
  Boot, MainMenu, StageSelect, TeamBuilder, Collection, Summon, Battle
src/
  data/                  Enums, Stats, HeroInstance + definitions/ (Resources)
  registry/              Catalogues (Heroes/Skills/StatusEffects/Enemies/Stages/Banners)Data
  autoload/              RNG, DataRegistry, GameState, SaveManager, AudioManager, SceneRouter
  combat/                CombatEngine, Combatant, DamageFormula, EnemyAI, StatusEffectInstance
  ui/                    Style, VisualKit, widgets, overlays
assets/fonts/            DejaVu Sans (libre)
tests/                   TestRunner.tscn + suites/ (185 assertions) + UISmoke
.github/workflows/       deploy.yml (tests → export Web → GitHub Pages)
```

### Autoloads (responsabilités)

- **RNG** : aléatoire centralisé, seedable (`seed_with`) pour les tests.
- **DataRegistry** : charge et indexe toutes les définitions par id.
- **GameState** : économie, collection, équipe, niveaux, invocation, (dé)sérialisation.
- **SaveManager** : sauvegarde JSON versionnée (`user://`), secours, migration.
- **AudioManager** : SFX/ambiances **synthétisés** (aucun fichier audio externe).
- **SceneRouter** : transitions avec fondu.

## Conventions

- GDScript typé. **Ne jamais** utiliser `:=` sur une valeur Variant (globaux
  `lerp/min/max/clamp`, `load()`, `Dictionary.get()`, retours de var non typées) :
  le projet traite ce warning comme une erreur. Utiliser `lerpf/minf/...` ou un
  type explicite (`var x: T = ...`).
- Logique de combat sans dépendance à la scène ; l'UI rejoue un **journal
  d'événements** produit par `CombatEngine.drain()`.
- Valeurs d'équilibrage uniquement dans `src/registry/`.
- Textes joueur en français.

## Commandes

```bash
# Construire le cache de classes (obligatoire avant un run headless propre)
godot --headless --import

# Tests (sortie code 0/1)
godot --headless res://tests/TestRunner.tscn

# Smoke test d'interface (instancie chaque écran)
godot --headless res://tests/UISmoke.tscn

# Export Web
godot --headless --export-release "Web" build/web/index.html
```

La CI (`.github/workflows/deploy.yml`) installe Godot 4.3 + templates, lance les
tests, exporte le Web et déploie sur GitHub Pages à chaque push sur `main`.

## Systèmes terminés (Phase 1)

Combat 4v4 (jauge, compétences data-driven, éléments, buffs/debuffs, DoT,
contrôle, bouclier, IA, boss) · 6 héros · 3 stages + boss · collection (filtres/
tri/fiche) · équipe 4 (anti-doublon, synergies) · invocation (taux, pitié,
doublons→fragments, animation) · progression niveaux · sauvegarde · tutoriel ·
paramètres · outils dev (debug) · export Web + déploiement Pages.

## Précautions avant modification

- Après avoir ajouté/renommé un `class_name`, relancer `--import` (cache de
  classes) avant tout run headless.
- Ne pas casser la séparation logique/scène du combat (garde la testabilité).
- La sauvegarde ne stocke que des identifiants + données joueur, jamais les
  définitions ; incrémenter `SAVE_VERSION` et gérer la migration si le format
  change.
- Garder `variant/thread_support=false` dans le preset Web (compatibilité
  GitHub Pages sans en-têtes COOP/COEP).
- Lancer les 185 tests avant de pousser.
