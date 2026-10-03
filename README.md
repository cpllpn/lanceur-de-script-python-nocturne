# Lanceur de scripts Python nocturne

Orchestrateur Windows qui enchaîne des scripts Python (analyses boursières US) après un allumage Wake-on-LAN, puis éteint le PC.

## Déroulement

```
Home Assistant (WoL) 01:30
        ↓
Planificateur de tâches ~01:33
        ↓
nightly_orchestrator.bat
        ↓
1. analyses-financieres / nightly_watchlist_run.py
2. Surveillance S&P 500 / sp500_dominance_tracker.py
        ↓
shutdown (60 s)
```

## Fenêtre d’exécution

| | |
|---|---|
| **Jours** | Mardi → Samedi |
| **Heures** | 01h00 – 03h00 |
| **Lundi** | ignoré (pas de Bourse le dimanche) |
| **Samedi** | reprise de la clôture du vendredi |

Hors de cette fenêtre, le `.bat` sort immédiatement : pas de scripts, pas d’extinction. Utile si le PC est allumé en journée et que la tâche se déclenche par erreur.

## Fichiers

| Fichier | Rôle |
|---------|------|
| `nightly_orchestrator.bat` | Orchestrateur principal |
| `AnalysesFinancieres-WatchlistNocturne.xml` | Export de la tâche Planificateur (optionnel) |
| `logs/orchestrator_last.log` | Dernier journal d’exécution |
| `LISEZMOI.txt` | Notes locales |

## Options

```bat
nightly_orchestrator.bat --force
nightly_orchestrator.bat --no-shutdown
nightly_orchestrator.bat --force --no-shutdown
```

| Option | Effet |
|--------|--------|
| `--force` | Ignore la fenêtre horaire / jours |
| `--no-shutdown` | Ne pas éteindre le PC (tests) |

## Prérequis

- Windows avec Python (`py`, ou `python` / Python 3.13)
- Les projets cibles déjà présents localement (chemins dans le `.bat`)
- Home Assistant (ou autre) pour le Wake-on-LAN
- Une tâche Planificateur pointant vers `nightly_orchestrator.bat`

## Planificateur de tâches

Configuration recommandée (plutôt que « Au démarrage ») :

1. **Actions**  
   - Programme : chemin vers `nightly_orchestrator.bat`  
   - Démarrer dans : dossier du lanceur  

2. **Déclencheurs**  
   - Hebdomadaire  
   - Mardi, Mercredi, Jeudi, Vendredi, Samedi  
   - Heure : `01:33:00`  

Le garde-fou `01h–03h mar–sam` dans le `.bat` reste une sécurité supplémentaire.

## Ajouter un script

Dans `nightly_orchestrator.bat`, avant le shutdown :

```bat
pushd "C:\chemin\vers\mon-projet"
"%PYEXE%" mon_script.py
popd
```

Le script Python ne doit **pas** faire de `shutdown` ni de `pause` : l’extinction est gérée une seule fois par l’orchestrateur.

## Licence

Usage personnel.
