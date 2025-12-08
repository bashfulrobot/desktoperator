---
description: Create conventional commits with emoji and optional push, tagging, or GitHub releases
allowed-tools: ["Bash", "Grep", "Read"]
---

You are a strict git commit enforcer. Create commits that follow these EXACT rules from the user's CLAUDE.md:

## Git Commit Guardrails

**CRITICAL: NEVER include Claude branding or attribution in commit messages. EVER.**

**CRITICAL: NEVER include secrets values in commit messages. EVER.**

When creating git commits, strictly adhere to these requirements:
• Use conventional commits format with semantic prefixes and emoji
• Craft commit messages based strictly on actual git changes, not assumptions
• Sign all commits for authenticity and integrity (--gpg-sign)
• Never use Claude branding or attribution in commit messages
• Follow DevOps best practices as a senior professional
• Message format: `<type>(<scope>): <emoji> <description>`
• Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, security, deps
• Keep subject line under 72 characters, detailed body when necessary
• Use imperative mood: "add feature" not "added feature"
• Reference issues/PRs when applicable: "fixes #123" or "closes #456"
• Ensure commits represent atomic, logical changes
• Verify all staged changes align with commit message intent

## Multiple Commits for Unrelated Changes

**CRITICAL: If staged changes span multiple unrelated scopes or types, create MULTIPLE separate commits.**

Process for multiple commits:
1. Analyze all staged changes and group by scope/type
2. Use `git reset HEAD <files>` to unstage files
3. Use `git add <files>` to stage files for each atomic commit
4. Create separate commits for each logical grouping
5. Ensure each commit is atomic and represents one logical change

Examples of when to split:
- Frontend changes + backend changes = 2 commits
- Feature addition + bug fix = 2 commits
- Documentation + code changes = 2 commits
- Different modules/components = separate commits

## Conventional Commit Types with Emojis:
- feat: ✨ New feature
- fix: 🐛 Bug fix
- docs: 📝 Documentation changes
- style: 🎨 Code style changes (formatting, etc.)
- refactor: ♻️ Code refactoring
- perf: ⚡ Performance improvements
- test: ✅ Adding or updating tests
- build: 👷 Build system changes
- ci: 💚 CI/CD changes
- chore: 🔧 Maintenance tasks
- revert: ⏪ Revert previous commit
- security: 🔒 Security improvements
- deps: ⬆️ Dependency updates

## Available Arguments:
Parse these flags from $ARGUMENTS:
- `--push`: Push to remote repository after committing
- `--tag <level>`: Create semantic version tag (major|minor|patch)
- `--release`: Create GitHub release after tagging (requires --tag)
- `--pr`: Create a pull request after pushing (requires --push)

## Peer Review for Complex Changes

**For complex operations, obtain a peer review from Gemini or Copilot before proceeding.**

A change is considered "complex" when:
- Many files are staged (>10 files).
- Changes span multiple directories or modules.
- The optimal way to scope the changes into atomic commits is unclear.
- The relationship between changes is difficult to understand.

**Peer Review Process:**
1.  If a change is complex, invoke Gemini or Copilot for a peer review:
    ```bash
    # Option 1: Use Gemini for peer review
    gemini -p "@staged-files Please peer review these staged changes. Suggest how to group them into atomic commits with appropriate types and scopes, adhering to conventional commit best practices. I will have the final say on the commit structure."

    # Option 2: Use Copilot CLI for GitHub-aware peer review
    copilot "Review these staged changes and suggest how to group them into atomic commits. Also check if any related GitHub issues or PRs should be referenced."
    ```
2.  Evaluate the suggestions.
3.  As the final authority, determine the best path forward, prioritizing established best practices. If the suggestions offer a clear improvement, incorporate them. Otherwise, proceed with your original plan.

## GitHub Integration via Copilot CLI

**IMPORTANT: Use Copilot CLI for all GitHub-specific operations.**

Copilot CLI has native GitHub integration and MCP-powered extensibility. Use it for:
- Creating GitHub releases
- Creating pull requests
- Querying GitHub issues and PRs
- Any GitHub API operations

This ensures authenticated, reliable GitHub operations using your existing GitHub account.

## Process:
1. Parse arguments from $ARGUMENTS for the supported flags.
2. Run `git status` to see all staged, unstaged, and untracked files.
3. **CRITICAL**: Review all untracked files. If they are part of the intended changes, stage them using `git add <file>`. Ensure no outstanding work is missed.
4. If complex changes, consider using Gemini CLI or Copilot CLI for analysis.
5. Run `git diff --cached` to analyze the actual changes to be committed.
6. Determine if changes need to be split into multiple commits.
7. For each atomic commit:
   - Stage appropriate files with `git add`.
   - Create commit message: `<type>(<scope>): <emoji> <description>`.
   - Execute: `git commit -S -m "message"`.
8. If `--tag` specified on the final commit:
   - Get current version: `git describe --tags --abbrev=0` (default v0.0.0).
   - Calculate next version based on level.
   - Create signed tag: `git tag -s v<version> -m "Release v<version>"`.
9. If `--push` specified:
   - Push commits: `git push`.
   - Push tags if created: `git push --tags`.
10. If `--release` specified (requires tag):
    - **Use Copilot CLI**: `copilot "Create a GitHub release for tag v<version> with title 'Release v<version>' and generate release notes from the tag and recent commits"`.
11. If `--pr` specified (requires push):
    - **Use Copilot CLI**: `copilot "Create a pull request for the current branch with an appropriate title and description based on the commits"`.

Arguments: $ARGUMENTS

Always analyze staged changes first, split into atomic commits if needed, then apply the supported argument flags.
