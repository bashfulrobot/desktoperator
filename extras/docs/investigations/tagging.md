# Ansible Tagging System Redesign

## Current Problems

### 1. **Include Role Tag Inheritance Issues**
When using `include_role`, tags on the include statement don't automatically run the tasks inside the role. Example:
```yaml
- name: Include Visual Studio Code
  include_role:
    name: apps/vscode
  tags: [vscode, editor, development]
```
Running `ansible-playbook site.yml --tags vscode` only executes the include statement, not the tasks inside the vscode role.

### 2. **Dependencies Not Automatic**
VSCode themes depend on COSMIC color extraction, but running `--tags vscode` alone doesn't include the color extraction tasks. You must manually add `--tags vscode,cosmic` or run the full playbook.

### 3. **Inconsistent Tag Application**
- Some roles use `import_tasks` with tags (system role)
- Some use `include_role` with tags (apps role)
- Some tasks have `tags: [always]` (justfile role)
- Tag inheritance behavior is inconsistent between these methods

### 4. **Tag Pollution**
Currently 46 different tags across the playbook, many overlapping or redundant:
- `vscode`, `editor`, `development` - all apply to the same role
- `cosmic`, `theme`, `colors` - overlap significantly
- No clear hierarchy or naming convention

### 5. **No Clear Use Cases**
Tags don't map well to common operations:
- "Update this one app" requires knowing exact tag name
- "Regenerate all themes" requires knowing `cosmic,vivaldi,vscode`
- "Run all development tools" requires listing multiple tags

## Proposed Solution

### Tag Hierarchy

```
Layer 1: Role-Level (Primary)
├── system          # Core system configuration
├── desktop         # Desktop environment
├── apps            # All applications
└── bootstrap       # Initial setup (never runs by default)

Layer 2: Functional Categories
├── dev             # Development tools (helix, vscode, go, etc.)
├── communication   # Chat/video (slack, zoom)
├── browser         # Web browsers (vivaldi, zen-browser)
├── productivity    # Task management (todoist)
└── infrastructure  # System services (firewall, tailscale, backup)

Layer 3: Dependency Tags (Auto-applied)
├── theme-consumer  # Anything that uses COSMIC colors
├── font-consumer   # Anything that uses custom fonts
└── system-admin    # System management tools

Layer 4: Specific Components (Minimal use)
├── vscode          # When you really only want VSCode
├── vivaldi         # When you really only want Vivaldi
└── [app-name]      # One tag per app
```

### Implementation Strategy

#### 1. **Use `apply` for Tag Inheritance**
Replace `include_role` with the `apply` keyword to ensure tags propagate:

```yaml
# BEFORE (broken)
- name: Include Visual Studio Code
  include_role:
    name: apps/vscode
  tags: [vscode, editor, development]

# AFTER (fixed)
- name: Include Visual Studio Code
  include_role:
    name: apps/vscode
    apply:
      tags: [vscode, dev, theme-consumer]
  tags: [always]  # Always evaluate the include, tags apply to tasks inside
```

#### 2. **Implement Dependency Management**
Use tag dependencies to automatically include required tasks:

```yaml
# In site.yml or group_vars
tag_dependencies:
  theme-consumer:
    - cosmic
    - colors
  vscode:
    - theme-consumer
  vivaldi:
    - theme-consumer
```

Then in pre_tasks:
```yaml
- name: Resolve tag dependencies
  set_fact:
    resolved_tags: "{{ ansible_run_tags | map('extract', tag_dependencies) | flatten | unique }}"
```

#### 3. **Standardize Tag Application**

**In site.yml:**
```yaml
roles:
  - role: system
    tags: [system, infrastructure]

  - role: desktop
    tags: [desktop, infrastructure]

  - role: apps
    tags: [apps]
```

**In roles/apps/tasks/main.yml:**
```yaml
- name: Include Visual Studio Code
  include_role:
    name: apps/vscode
    apply:
      tags: [vscode, dev, theme-consumer]
  tags: [always]
  when: "'vscode' in common_apps"

- name: Include Vivaldi
  include_role:
    name: apps/vivaldi
    apply:
      tags: [vivaldi, browser, theme-consumer]
  tags: [always]
  when: "'vivaldi' in common_apps"
```

**In roles/system/tasks/main.yml:**
```yaml
- name: Import COSMIC theme color extraction
  import_tasks: cosmic-theme.yml
  tags: [cosmic, theme, colors, theme-provider]
```

#### 4. **Add Dependency Tracking to Individual Roles**

**In roles/apps/vscode/tasks/main.yml:**
```yaml
# At the top of the file
- name: Ensure COSMIC colors are available
  assert:
    that:
      - theme_colors_dark is defined
      - theme_colors_light is defined
    fail_msg: "VSCode themes require COSMIC colors. Run with --tags cosmic,vscode or no tags."
  tags: [always]
```

### Common Usage Patterns

After implementation:

```bash
# Update single app (auto-includes dependencies)
ansible-playbook site.yml --tags vscode

# Update all development tools
ansible-playbook site.yml --tags dev

# Update all apps
ansible-playbook site.yml --tags apps

# Regenerate all themes (anything that consumes COSMIC colors)
ansible-playbook site.yml --tags theme-consumer

# Update system without apps
ansible-playbook site.yml --tags system,desktop

# Full run (no tags)
ansible-playbook site.yml
```

### Migration Plan

#### Phase 1: Fix Critical Issues (Priority 1)
1. Add `apply` keyword to all `include_role` statements in `roles/apps/tasks/main.yml`
2. Add `tags: [theme-consumer]` to vscode and vivaldi roles
3. Test that `--tags vscode` now works correctly

#### Phase 2: Standardize Categories (Priority 2)
1. Audit all existing tags and map to new hierarchy
2. Update all role includes with standardized tags
3. Remove redundant tags (keep only hierarchy tags)
4. Document tag usage in README.md

#### Phase 3: Add Dependency System (Priority 3)
1. Create tag dependency mapping in group_vars or site.yml
2. Add pre_tasks to resolve dependencies
3. Add assertions in theme-consuming roles
4. Test all common usage patterns

#### Phase 4: Cleanup (Priority 4)
1. Remove old/unused tags
2. Add tag linting to prevent regression
3. Update jsys to show common tag combinations
4. Create aliases for common operations

## Tag Reference (After Redesign)

### Role-Level Tags (Run entire role)
- `system` - Core system packages, users, SSH, firewall
- `desktop` - Desktop environment configuration
- `apps` - All applications
- `bootstrap` - Initial system setup (never runs unless specified)

### Functional Category Tags (Run group of related apps)
- `dev` - Development tools: vscode, helix, go, claude-code
- `communication` - Communication apps: slack, zoom
- `browser` - Web browsers: vivaldi, zen-browser
- `productivity` - Productivity apps: todoist, 1password
- `infrastructure` - System services: firewall, tailscale, restic

### Dependency Tags (Usually not used directly)
- `theme-consumer` - Apps that need COSMIC colors (vscode, vivaldi)
- `theme-provider` - Tasks that generate theme data (cosmic-theme)
- `font-consumer` - Apps that need custom fonts
- `system-admin` - System management tools (justfile)

### Specific Component Tags (Use sparingly)
- Individual app names: `vscode`, `vivaldi`, `helix`, etc.
- Specific subsystems: `cosmic`, `fonts`, `firewall`, etc.

## Testing Checklist

After implementation, verify:

- [ ] `ansible-playbook site.yml --tags vscode` creates code-flags.conf and themes
- [ ] `ansible-playbook site.yml --tags dev` runs all dev tools
- [ ] `ansible-playbook site.yml --tags apps` runs all apps
- [ ] `ansible-playbook site.yml --tags theme-consumer` regenerates all themes
- [ ] `ansible-playbook site.yml --tags vscode --list-tasks` shows COSMIC color extraction
- [ ] `ansible-playbook site.yml --list-tags` shows clean, organized tag list
- [ ] Running with no tags still works (full playbook)
- [ ] jsys update-ansible-tags works with new tag structure

## Benefits

1. **Predictable Behavior**: Tags work consistently across all roles
2. **Automatic Dependencies**: No need to remember `--tags vscode,cosmic`
3. **Cleaner Tag List**: From 46 tags down to ~20 meaningful tags
4. **Better DX**: Common operations map to intuitive tag names
5. **Self-Documenting**: Tag hierarchy makes intent clear
6. **Maintainable**: Easy to add new apps following established patterns

## Notes

- Keep `bootstrap` with `tags: [bootstrap, never]` - this is correct
- The `always` tag on include statements means "always evaluate the include", not "always run the tasks"
- Use `import_tasks` for tasks that should always be evaluated (like cosmic-theme)
- Use `include_role` with `apply` for conditional role inclusion (like apps)
