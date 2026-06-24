# Game Design — Cendres & Cristaux (Phase 1)

Document de conception du prototype. Toutes les valeurs sont **configurables**
dans les fichiers de données (`src/registry/`), jamais codées en dur dans la
logique de combat.

## Vision

RPG gacha 2D au tour par tour, vue latérale, combats 4 contre 4 avec jauge de
vitesse. Le plaisir vient de : invoquer des héros → découvrir leurs compétences
→ composer une équipe → comprendre les synergies → combattre manuellement →
progresser → débloquer de nouvelles invocations. Projet 100 % original (noms,
compétences, visuels, histoire).

## Boucle principale

Ouvrir le jeu → équipe de départ offerte → consulter la collection → composer
une équipe de 4 → choisir un stage → combattre manuellement → gagner or / XP /
cristaux → améliorer les héros par niveau → invoquer → ajuster l'équipe →
vaincre le boss du chapitre 1.

## Éléments

Trois éléments : **Feu, Eau, Nature**. Cycle : Feu > Nature > Eau > Feu.

- Avantage élémentaire : dégâts ×1.30, +0.10 à l'application des debuffs.
- Désavantage : dégâts ×0.75 (jamais d'échec automatique total).
- Affichage : icône vectorielle + couleur + infobulle (l'icône ne dépend pas que
  de la couleur).

## Rôles

- **Défenseur** : survie, bouclier, provocation.
- **Attaquant** : dégâts élevés, critique, exécution.
- **Soutien** : buffs, debuffs, contrôle, manipulation de jauge.
- **Soigneur** : soins, purification, régénération.

Les rôles décrivent le héros mais ne limitent pas ses compétences.

## Statistiques

PV, Attaque, Défense, Vitesse, Taux critique, Dégâts critiques, Précision
(application des debuffs), Résistance (résistance aux debuffs). Les pourcentages
sont stockés en fraction (0.15 = 15 %).

## Formule de dégâts (centralisée — `src/combat/DamageFormula.gd`)

```
dégâts = ATQ_eff × multiplicateur_compétence × bonus_conditionnel
       × (1 − DEF_eff / (DEF_eff + 300))      ← réduction par la défense
       × modificateur_élémentaire             ← 1.30 / 0.75 / 1.0
       × critique                             ← × Dégâts_crit si coup critique
       × variation                            ← aléatoire 0.97 … 1.03
```

Résultat arrondi, minimum 1. La variance est volontairement faible pour rester
lisible. `bonus_conditionnel` couvre : bonus si la cible a un statut, bonus par
debuff, exécution sous un seuil de PV.

Probabilité d'appliquer un debuff :
`chance = base + précision − résistance (+0.10 si avantage)`, bornée à
[5 %, 95 %] sauf compétence explicitement garantie (base ≥ 100 %).

## Jauge d'action

Jauge 0 → 100 remplie selon la Vitesse. À 100, l'unité agit ; après l'action sa
jauge est réduite de 100 (le **surplus est conservé**). Calcul analytique (pas
de boucle infinie ; garde-fou à 800 tours).

## Buffs / Debuffs

Buffs : Attaque+, Défense+, Vitesse+, Critique+, Bouclier, Régénération.
Debuffs : Attaque−, Défense−, Vitesse−, Brûlure, Poison, Étourdissement, Gel,
Provocation.

- Durée exprimée en tours de l'unité affectée (avec délai de grâce le tour
  d'application).
- Brûlure/Poison : dégâts au début du tour de la cible. Poison cumulable (×3).
- Étourdissement/Gel : empêchent l'action sans casser la jauge.
- Bouclier : absorbe les dégâts avant les PV.

## Héros du prototype (6)

| Héros | Élément | Rôle | Rareté | Identité |
|-------|---------|------|--------|----------|
| Kaelen | Feu | Attaquant | 3★ | Guerrier offensif, met le feu et frappe les cibles brûlées |
| Brask | Feu | Défenseur | 4★ | Provoque et offre des boucliers d'équipe |
| Néria | Eau | Soigneur | 3★ | Soigne et purifie de façon fiable |
| Selka | Eau | Soutien | 4★ | Gèle, ralentit et vole le tempo |
| Elyra | Nature | Soutien | 3★ | Accélère l'équipe, réduit les défenses |
| Vaeron | Nature | Attaquant | 5★ | Empoisonneur qui exécute les cibles affaiblies |

Chaque héros possède 3 compétences (détails dans `src/registry/SkillsData.gd`).

## Progression

Niveau max Phase 1 : **20**. XP gagnée à chaque victoire (par héros de l'équipe).
À la montée de niveau : PV/ATQ/DEF augmentent (Vitesse pour certains héros).
Courbe : `XP requise = 80 + (niveau − 1) × 55`.

Pas encore : éveil, 6★, équipement, runes, talents, fusion (phases ultérieures).

## Économie

Deux monnaies : **Or** (améliorations futures) et **Cristaux d'invocation**.
Sources de cristaux : premières victoires, récompenses de stage, boss, lancement.
Pas de monnaie premium, énergie, pub, ou offres temporaires.

## Invocation

Bannière permanente « Portail des Origines ».

- Taux : 3★ 75 %, 4★ 22 %, 5★ 3 % (total 100 %).
- Coût : ×1 = 100 cristaux, ×10 = 1000 cristaux.
- Première invocation **gratuite** et garantit un héros nouveau.
- Premier (et chaque) ×10 garantit au moins un 4★.
- Pitié : 5★ garanti au 40e tirage sans 5★, compteur remis à zéro ensuite.
- Doublons → fragments (3★ : 10, 4★ : 20, 5★ : 40), sauvegardés et affichés
  (dépensables en phase 2).

## Chapitre 1 — Les Ruines de Cendre

- **1-1 Entrée des Ruines** : 3 ennemis, tutoriel.
- **1-2 Salle des Gardes** : 4 ennemis (défenseur + attaquants + soutien).
- **1-3 Le Gardien des Cendres** : boss Feu + 2 servants. Enrage sous 50 % PV
  (une fois), gagne de la jauge à la mort d'un servant (sans boucle infinie).

## Héros de départ

Kaelen (dégâts), Néria (soin), Elyra (soutien), Brask (survie). L'équipe de
départ permet de finir le chapitre 1 sans dépendre du gacha.
