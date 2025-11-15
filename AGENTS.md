# Multi-AI Development Workflow - Desktoperator Project

This repository uses a sophisticated multi-AI development workflow. If you are an AI agent working in this codebase, please read and follow these guidelines.

## Project Context

**Desktoperator** is an Ansible-based infrastructure-as-code project for managing Linux desktop environments. It handles application installation, configuration management, and system setup.

## Active AI Agents in This Workflow

| Agent | Model | Role | When to Engage |
|-------|-------|------|----------------|
| **Claude Code** | Sonnet 4.5 | Orchestrator & executor | All file/git operations, final decisions |
| **Codex CLI** | GPT-5.1 Codex | Planner & implementer | Complex features requiring deep planning |
| **Gemini CLI** | Gemini 2.5 Pro | Strategic advisor | Architectural review, alternatives |
| **Copilot CLI** | Sonnet 4.5 / GPT-5.1 | GitHub specialist | PR reviews, issues, Actions debugging |

## Four-Phase Development Workflow

### Phase 1: Planning (Codex - High Thinking, Read-Only)

When planning new features or complex changes:

```bash
codex --readonly --model gpt-5-pro --reasoning-effort high
```

**Focus on:**
- Understanding Ansible role structure (`roles/apps/`, `roles/system/`)
- Identifying which roles need modification
- Planning deployment tasks and file templates
- Considering idempotency and cross-platform compatibility

### Phase 2: Implementation (Codex - Fast Iteration)

```bash
codex --model gpt-5-pro
```

**Focus on:**
- Writing Ansible tasks following project patterns
- Creating Jinja2 templates for configuration files
- Ensuring proper file ownership and permissions
- Following YAML best practices

### Phase 3: Multi-AI Review (All Agents, Read-Only)

**Claude Code reviews:**
- Ansible syntax and best practices
- File permissions and ownership
- Idempotency of tasks
- Cross-distro compatibility

**Gemini CLI reviews:**
- Role architecture and organization
- Separation of concerns
- Reusability of tasks
- Overall system design

**Copilot CLI reviews:**
- Security (secrets, credentials, file permissions)
- GitHub Actions workflows if modified
- Any PR context and discussion

### Phase 4: Iteration (Codex)

Address feedback from all reviewers and improve the implementation.

## Project-Specific Guidelines

### Ansible Best Practices

1. **Role Structure**
   ```
   roles/
   ├── apps/           # Application installation and configuration
   │   └── <app-name>/
   │       ├── tasks/main.yml
   │       ├── files/
   │       └── templates/
   └── system/         # System-level configuration
       └── <component>/
   ```

2. **Task Patterns**
   - Use `app_states` dictionary for install/uninstall logic
   - Always include `when:` conditions for conditional execution
   - Set `become: true` only when needed (privilege escalation)
   - Use `register:` and `changed_when:` for proper idempotency

3. **File Management**
   - Config files → `files/` (static) or `templates/` (Jinja2)
   - Always set explicit `owner`, `group`, and `mode`
   - Use `{{ user.name }}` and `{{ user.home }}` variables

4. **Security**
   - Never hardcode credentials
   - Use 1Password integration via `op://` references
   - Sensitive files should be mode `0600` or `0400`
   - Global configs go to `~/.config/` or tool-specific home dirs

### Multi-AI Configuration Pattern

When adding new AI CLI tools (like we just did with Codex), follow this pattern:

```yaml
# roles/apps/<tool>-cli/tasks/main.yml
---
- name: Install <tool> CLI
  ansible.builtin.command: npm install -g @org/<tool>
  become: true
  when: app_states['<tool>-cli'] | default('present') == 'present'

- name: Create .<tool> directory
  ansible.builtin.file:
    path: "{{ user.home }}/.<tool>"
    state: directory
    owner: "{{ user.name }}"
    mode: "0755"

- name: Deploy global configuration
  ansible.builtin.copy:
    src: <config-file>
    dest: "{{ user.home }}/.<tool>/<config-file>"
    owner: "{{ user.name }}"
    mode: "0644"
```

### Documentation

- User documentation → `extras/docs/`
- Ansible architecture → `extras/docs/ansible-architecture.md`
- This workflow → `extras/docs/multi-ai-workflow.md`

## Agent-Specific Instructions

### For Codex

When working in this repo:
- **Planning:** Explore the existing role structure before proposing changes
- **Implementation:** Match the patterns used in similar roles
- **Ansible:** Ensure tasks are idempotent and handle both install/uninstall
- **Testing:** Consider multi-distro compatibility (Ubuntu/Pop!_OS focus)

### For Gemini

When reviewing this repo:
- **Architecture:** Evaluate role organization and separation of concerns
- **Reusability:** Identify opportunities to consolidate common patterns
- **Scalability:** Consider how the structure scales with more apps/configs
- **Alternatives:** Suggest simpler approaches if current seems complex

### For Copilot

When working with this repo on GitHub:
- **Security:** Focus on secrets handling via 1Password integration
- **CI/CD:** Review any GitHub Actions workflow changes
- **PRs:** Check for proper commit messages (conventional commits format)
- **Issues:** Understand that this is a personal infrastructure project

## Workflow Reference

For complete workflow details, examples, and best practices:
- `extras/docs/multi-ai-workflow.md` - Comprehensive guide
- `roles/apps/claude-code/files/CLAUDE.md` - Claude's global instructions
- `roles/apps/codex-cli/files/AGENTS.md` - Codex's global instructions
- `roles/apps/gemini-cli/files/commands/review.toml` - Gemini's review role

## Current State

This repository is actively using:
- ✅ Claude Code (primary orchestrator)
- ✅ Gemini CLI (strategic review via peer review workflow)
- ✅ Codex CLI (planning & implementation)
- ✅ Copilot CLI (GitHub operations)

All global configurations are managed via Ansible roles and deployed to `~/.config/` and tool-specific home directories.

## Questions?

If you're an AI agent and uncertain about how to proceed:
1. **Codex:** Ask Claude Code for clarification
2. **Gemini:** Provide multiple strategic alternatives
3. **Copilot:** Focus on your GitHub integration strengths
4. **Claude:** You're in charge - synthesize and decide

The human developer (Dustin) has final authority on all decisions.
