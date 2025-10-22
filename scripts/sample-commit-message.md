---- Command Sample ---

git diff --staged | grep + | gemini -p "Summarize changes and look at scripts/sample-commit-message.md to see a sample message and formatting."

---- SAMPLE COMMIT ----

(I will add main title)

### 1. Development Workflow (`jdev`)

- **New `jdev` Command:** A wrapper script `/usr/local/bin/jdev` is created to execute development-related recipes from a system-wide `justfile`.
- **`dev` Justfile Module:** A new `dev.just.j2` module is added, providing a suite of recipes grouped under `dev`. These include:
    - **Git Helpers:** Interactive commits, status, log, diff, staging, amending, and interactive rebasing.
    - **Project Utilities:** Recipes for finding files, searching text, and counting lines of code (`tokei`).
- **Interactive Commits:** A new script `git-commit-gum.sh` is added to provide an interactive experience for creating conventional commits with emoji prefixes.
- **Shell Integration:** Fish shell completions for the new `jdev` command are automatically installed.

### 2. Flatpak Application Management

- **Centralized App State:** A new `app_states` dictionary is added to `roles/apps/defaults/main.yml` to centrally manage the desired state (e.g., `present`, `absent`) of applications.
- **Declarative Flatpaks:** A `flatpak_apps` list is introduced in `roles/system/defaults/main.yml` to define Flatpak applications to be managed.
- **Ansible Tasks:** New tasks in `roles/system/tasks/flatpak.yml` use the `community.general.flatpak` module to install or remove Flatpaks based on the `flatpak_apps` list and their corresponding state in `app_states`.
- **Initial Applications:** `Todoist` and `Kooha` are the first two applications added to be managed by this new system.
