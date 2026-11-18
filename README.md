# openuem-dev

Outillage de développement pour contribuer à [OpenUEM](https://github.com/open-uem).
Ce dépôt ne contient aucun code OpenUEM : il construit des images à partir
des forks et les publie sur GHCR. Les forks restent intacts, leurs branches
peuvent donc être proposées telles quelles au projet amont.

## Contenu

| Chemin | Rôle |
|---|---|
| `.github/workflows/build-images.yml` | Construit et publie `openuem-console`, `openuem-worker` et `openuem-dev-endpoint` |
| `endpoint/Dockerfile` | Image du poste Linux de test (Debian 13 + agent compilé depuis le fork) |
| `endpoint/entrypoint.sh` | Écrit `openuem.ini` au premier démarrage puis lance l'agent |

## Mise en place

1. Forker dans le même compte : `openuem-console`, `openuem-worker`,
   `openuem-agent`, `ent`, `nats`, `openuem-ansible-config`, `utils`.
2. Créer ce dépôt et y pousser les trois fichiers ci-dessus.
3. Onglet Actions, workflow `build-images`, bouton "Run workflow".
4. Dans les paquets du compte, passer les trois images en visibilité publique
   si le serveur ne doit pas s'authentifier sur `ghcr.io`.

## Paramètres du workflow

| Paramètre | Rôle | Défaut |
|---|---|---|
| `console_ref`, `worker_ref`, `agent_ref` | Branche, tag ou SHA à construire dans chaque fork | `main` |
| `use_local_libs` | Remplace les bibliothèques partagées par les forks | non |
| `ent_ref`, `nats_ref`, `ansible_config_ref`, `utils_ref` | Branches des bibliothèques (avec `use_local_libs`) | `main` |
| `image_tag` | Tag publié sur GHCR | `dev` |
| `fork_owner` | Propriétaire des forks | propriétaire de ce dépôt |

Exemple pour une tâche APT qui touche `openuem-ansible-config` et
`openuem-worker` : `worker_ref=feat-apt-tasks`, `use_local_libs=true`,
`ansible_config_ref=feat-apt-tasks`.

## Points d'attention

- Les Dockerfile amont de la console et du worker sont utilisés tels quels.
  Seule la ligne `FROM golang:` est alignée sur la version déclarée dans
  `go.mod`, car les images golang officielles refusent de compiler un module
  qui demande une version plus récente.
- L'image endpoint n'embarque ni systemd ni `openuem-agent-updater`.
