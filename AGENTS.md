# Repository Guidelines

## Project Structure & Module Organization
Root playbooks (`site.yml`, `bootstrap.yml`, `maintenance.yml`, `security-check.yml`) orchestrate roles and stay at the repository root. Host data sits in `inventory/`: shared config in `group_vars/all/`, host overrides in `host_vars/`, secrets encrypted in `vault.yml`. Role logic lives in `roles/`, with applications nested as `roles/apps/<app-name>/`; docs live in `docs/`, scripts in `scripts/`, and task wrappers in the root `justfile` plus topical `justfiles/`.

## Build, Test, and Development Commands
- `just bootstrap` – Install Ansible dependencies and prep a fresh machine.
- `just run` – Apply the full configuration to the current host.
- `just check` – Dry-run the playbook with `--check --diff` to preview changes.
- `just syntax` / `just lint` – Quick validation via syntax check and `ansible-lint`.
- `just tags` or `just tasks` – Inspect available tags or task lists before targeted runs.
- `jsys update-all` / `jsys update-ansible` – Post-bootstrap daily operations.

## Coding Style & Naming Conventions
Use YAML with two-space indentation, list items prefixed by `-`, and explicit task `name` values that start with an imperative verb. Role, tag, and file names follow kebab-case (`apps/restic`, `system-packages`). Prefer snake_case variables and declare defaults in `roles/<role>/defaults/main.yml`. When adding nested app roles, include them via `include_role` to preserve Ansible context, for example:

```yaml
- name: Ensure restic is installed
  include_role:
    name: apps/restic
  tags: [backup, restic]
```

## Testing Guidelines
Before proposing changes, run `just lint` and `just syntax`; both should pass. Use `just check` for idempotency verification and capture noteworthy diffs. For targeted validation, execute `ansible-playbook site.yml --limit $(hostname) --tags "<tag>" --check`. Update `docs/` or `STRUCTURE.md` whenever roles or variables reshape the architecture.

## Commit & Pull Request Guidelines
Follow the established Conventional Commit pattern with emoji prefixes (`✨ feat(scope): …`, `🐛 fix(scope): …`). Group related Ansible edits together and reference affected roles or hosts. Pull requests should summarise intent, link issues when available, list validation commands (`just lint`, `just check`), and flag related docs or inventory updates. Add screenshots or terminal snippets when COSMIC state changes are visible.

## Security & Configuration Tips
Review `docs/SECURITY.md` and `docs/1PASSWORD_SETUP.md` before touching secrets. Store new credentials in 1Password, rotate vault material per `docs/VAULT_KEY_MANAGEMENT.md`, and confirm `ansible.cfg` keeps `ansible_connection: local` to avoid remote drift.
