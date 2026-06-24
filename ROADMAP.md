# ROADMAP — Cendres & Cristaux

## Phase 1 — Prototype fondateur (état : TERMINÉE)

Tranche verticale jouable du menu au boss, exportée en Web.

### État des systèmes

| Système | État |
|---------|------|
| Projet Godot 4.3 + rendu gl_compatibility + responsive | ✅ |
| Architecture data-driven (definitions / instances / logique / UI) | ✅ |
| Autoloads (RNG, DataRegistry, GameState, SaveManager, AudioManager, SceneRouter) | ✅ |
| Menu principal (navigation, ressources, équipe) | ✅ |
| Combat 4v4 (jauge, ciblage manuel, IA, victoire/défaite) | ✅ |
| Formule de dégâts centralisée + éléments (Feu/Eau/Nature) | ✅ |
| Buffs/debuffs (incl. brûlure, poison, gel, étourdissement, bouclier, provocation) | ✅ |
| 6 héros originaux (3 compétences chacun) | ✅ |
| Chapitre 1 : 3 stages + boss (enrage, jauge sur mort de sbire) | ✅ |
| Progression : XP + montée de niveau (max 20) | ✅ |
| Collection (filtres, tri, fiche héros) | ✅ |
| Composition d'équipe (4, anti-doublon, synergies) | ✅ |
| Invocation (taux 75/22/3, pitié 40, doublons→fragments, animation) | ✅ |
| Sauvegarde versionnée + secours + migration | ✅ |
| Tutoriel (une seule fois) | ✅ |
| Paramètres (vitesse, sons, musique, réinitialisation) | ✅ |
| Outils de développement (build debug uniquement) | ✅ |
| Tests headless (185 assertions) + smoke UI | ✅ |
| Export Web + déploiement GitHub Pages (CI) | ✅ |

### Bugs connus / limites

- Animation de combat volontairement simple (lunge/impact/flottants). Pas de
  squelettes ni de spritesheets.
- L'IA est heuristique (pas de planification multi-tours).
- L'avertissement navigateur « AudioContext … user gesture » est normal : le son
  démarre au premier clic.
- Prévision de l'ordre des tours approximative (ignore les futurs effets de jauge
  et étourdissements).

### Assets temporaires (à remplacer en phase ultérieure)

- **Sprites & portraits** : silhouettes **procédurales vectorielles** (couleur
  dominante + arme + type de corps) dessinées dans `src/ui/VisualKit.gd`.
  Cohérents et distincts, mais provisoires — destinés à être remplacés par de
  vraies illustrations.
- **Sons / musiques** : entièrement **synthétisés** au démarrage
  (`src/ui/../autoload/AudioManager.gd`). Placeholders à remplacer.
- **Police** : DejaVu Sans (libre) — peut être remplacée par une police de marque.
- **Icône** : `icon.svg` provisoire.

Aucun asset n'est issu d'un jeu existant ; aucun téléchargement sans licence claire.

## Phase 2 — Pistes (à valider après le prototype)

- Dépense des fragments : éveil / amélioration des héros.
- Équipement en sets, donjons de ressources.
- Amélioration des compétences.
- Plus de héros et d'éléments, chapitres supplémentaires.
- Vraie progression long terme (au-delà du niveau 20).
- Illustrations et bande-son définitives.

Interdit en Phase 1 (réservé plus tard) : PvP, guildes, chat, boutique réelle,
pubs, énergie, monde ouvert, 3D, runes, classements, comptes en ligne, auto-farm.
