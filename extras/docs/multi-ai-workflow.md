# Multi-AI Development Workflow

A sophisticated workflow leveraging multiple AI tools for planning, implementation, and review.

## Philosophy

Different AI tools excel at different stages of development:
- **Planning** requires deep reasoning and exploration (high thinking)
- **Implementation** benefits from fast iteration (minimal thinking)
- **Review** gains from diverse perspectives (multi-model consensus)

This workflow separates these concerns and uses the right tool at the right time.

## The Four-Phase Workflow

```
┌─────────────────────────────────────────────────────────┐
│  Phase 1: PLANNING (Codex - High Thinking, Read-Only)  │
│  → Deep exploration and strategy                        │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 2: IMPLEMENTATION (Codex - Minimal Thinking)     │
│  → Fast iteration with o1/o3 5.1+ models               │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 3: MULTI-AI REVIEW (Claude/Gemini/Copilot)      │
│  → Three perspectives on unstaged changes (read-only)   │
└────────────┬────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────┐
│  Phase 4: ITERATION (Codex - Implementation)            │
│  → Address review feedback and refine                   │
└─────────────────────────────────────────────────────────┘
             │
             └──→ Back to Phase 3 if needed, or commit
```

## Phase Breakdown

### Phase 1: Planning with Codex (High Thinking, Read-Only)

**Purpose**: Explore codebase and form comprehensive plan with deep reasoning

**Configuration**:
- Mode: `--readonly` (no file modifications)
- Thinking: `--high-thinking` or equivalent (maximum reasoning)
- Model: Latest Codex/o-series models

**Activities**:
- Analyze existing code patterns
- Identify dependencies and impacts
- Consider edge cases and architecture
- Form detailed implementation plan
- Document assumptions and decisions

**Example Commands**:
```bash
# Start planning session
codex --readonly --high-thinking

# Typical planning prompts
codex> "Analyze the authentication module and plan how to add OAuth2 support"
codex> "What files will be affected? What are the risks?"
codex> "Create a step-by-step implementation plan"
```

**Exit Criteria**:
- Plan is comprehensive and addresses edge cases
- You understand and agree with the approach
- All questions/concerns are resolved

---

### Phase 2: Implementation with Codex (Minimal Thinking)

**Purpose**: Execute the plan with fast iteration

**Configuration**:
- Mode: `--write` (allow file modifications)
- Thinking: `--minimal-thinking` (faster execution)
- Model: o1-plus, o3-plus, or latest 5.1+ models

**Activities**:
- Implement according to plan
- Write code, tests, documentation
- Make incremental progress
- Fast iteration without overthinking

**Example Commands**:
```bash
# Start implementation session
codex --minimal-thinking

# Execution prompts
codex> "Implement the OAuth2 provider class as planned"
codex> "Add tests for the authentication flow"
codex> "Update documentation"
```

**Exit Criteria**:
- Implementation complete per plan
- All planned files created/modified
- Ready for review (don't commit yet!)

---

### Phase 3: Multi-AI Review (Claude/Gemini/Copilot, Read-Only)

**Purpose**: Get diverse perspectives on implementation quality

**Configuration**:
- All tools in `--readonly` mode
- Review unstaged changes only
- Each AI brings different strengths

**Tool Roles**:

| Tool | Model | Strength | Focus Area |
|------|-------|----------|------------|
| **Claude Code** | Sonnet 4.5 | General architecture, implementation quality | Does it follow best practices? |
| **Gemini CLI** | Gemini 2.5 Pro | Strategic thinking, alternatives | Is there a better approach? |
| **Copilot CLI** | Sonnet 4.5 (default) or GPT-5.1 | GitHub integration, security | GitHub context? Vulnerabilities? |

**Important**: Copilot CLI has **native GitHub integration** with your existing account - it can access repos, issues, and PRs using natural language. **Always prefer Copilot for GitHub operations** (PR reviews, issue analysis, etc.).

**Model diversity note**: By default you get Claude (Sonnet 4.5) + Gemini (2.5 Pro) + Copilot (Sonnet 4.5). For different model perspectives, Copilot supports:
- Claude: Sonnet 4.5 (default), Sonnet 4, Haiku 4.5
- OpenAI: GPT-5, GPT-5.1, GPT-5.1-Codex, GPT-5.1-Codex-Mini

Switch via: `COPILOT_MODEL=gpt-5.1` or configure permanently in Copilot settings.

**Example Commands**:
```bash
# Run all three reviews in parallel
claude --readonly "Review unstaged changes for quality and best practices" &
gemini -p "@unstaged-changes Peer review this implementation" &
gh copilot suggest "Security and quality review of unstaged changes" &  # Sonnet 4.5 default
wait

# Or for maximum model diversity, use GPT-5 in Copilot
claude --readonly "Review unstaged changes" &
gemini -p "@unstaged-changes Review implementation" &
COPILOT_MODEL=gpt-5 gh copilot suggest "Review unstaged changes" &
wait

# Or sequentially with saved notes
claude --readonly "Review unstaged changes" > review-claude.md
gemini -p "@unstaged-changes Review implementation" > review-gemini.md
gh copilot suggest "Security and GitHub-aware review" > review-copilot.md
```

**Review Checklist**:
- [ ] Architecture/design patterns
- [ ] Security vulnerabilities
- [ ] Performance concerns
- [ ] Test coverage
- [ ] Documentation completeness
- [ ] Error handling
- [ ] Edge cases
- [ ] Code style/consistency

**Exit Criteria**:
- All three AIs have provided feedback
- Critical issues identified
- Consensus on what needs improvement

---

### Phase 4: Iteration with Codex

**Purpose**: Address review feedback and refine implementation

**Configuration**:
- Mode: `--write` (modifications allowed)
- Thinking: `--minimal-thinking` (unless major rework needed)
- Model: Same as Phase 2

**Activities**:
- Address security concerns
- Fix bugs identified in review
- Improve code quality
- Add missing tests
- Update documentation

**Example Commands**:
```bash
codex --minimal-thinking

codex> "Address these review concerns: @review-claude.md @review-gemini.md @review-copilot.md"
codex> "Fix the security vulnerability in auth validation"
codex> "Add edge case tests suggested by reviewers"
```

**Exit Criteria**:
- All critical feedback addressed
- Security concerns resolved
- Ready for commit, or cycle back to Phase 3 for re-review

---

## Decision Points

### When to Use High Thinking vs Minimal Thinking?

**High Thinking** (Planning):
- Complex architectural decisions
- Unfamiliar codebase/problem domain
- High-risk changes (security, core functionality)
- Need to explore multiple approaches

**Minimal Thinking** (Implementation):
- Executing a known plan
- Straightforward implementations
- Iterating on feedback
- Time-sensitive changes

### When to Skip Multi-AI Review?

**Always review** for:
- Security-sensitive code
- Public APIs
- Database migrations
- Authentication/authorization
- Core business logic

**Can skip** for:
- Documentation-only changes
- Simple bug fixes (typos, etc.)
- Style/formatting changes
- Adding comments

### When to Re-review (Phase 3 Again)?

Go back to Phase 3 if:
- Major refactoring was needed
- Security vulnerabilities were fixed
- Architecture changed during iteration
- Multiple cycles of feedback (sanity check)

## Best Practices

### 1. Document the Plan
After Phase 1, save Codex's plan to a file:
```bash
# In Codex session
codex> "Save the implementation plan to PLAN.md"
```

### 2. Keep Review Context Small
Review unstaged changes only (not entire codebase):
```bash
git diff > current-changes.patch
# Share this with reviewers
```

### 3. Batch Reviews Efficiently
Run all three AI reviews in parallel to save time:
```bash
# Shell function for multi-AI review
multi-ai-review() {
  echo "🤖 Starting multi-AI review..."

  claude --readonly "Review @unstaged-changes for quality and best practices" &
  gemini -p "@unstaged-changes Peer review implementation and architecture" &

  # Default: Use Sonnet 4.5 (fast, GitHub-native)
  # gh copilot suggest "Review unstaged changes for security and quality" &

  # Or: Use GPT-5 for model diversity
  COPILOT_MODEL=gpt-5 gh copilot suggest "Review unstaged changes" &

  wait
  echo "✅ All reviews complete"
}

# Quick version (just Copilot for GitHub-aware review)
github-review() {
  gh copilot suggest "Review unstaged changes with GitHub context"
}
```

### 4. Track Iterations
Create a log of review cycles:
```bash
# Review cycle 1
mkdir -p .ai-reviews/cycle-1
# Save review outputs here

# Review cycle 2
mkdir -p .ai-reviews/cycle-2
# Compare with cycle 1
```

### 5. Use Read-Only Religiously
During planning and review, **always** use read-only mode to prevent:
- Accidental modifications
- Conflicting changes from multiple tools
- Loss of work

### 6. Git Hygiene
```bash
# Before starting
git checkout -b feature/new-work
git commit -a -m "WIP: baseline before AI workflow"

# After each phase
git add -p  # Review changes carefully
git commit -m "feat: implement X (Phase 2 complete)"
git commit -m "fix: address AI review feedback (Phase 4)"
```

## Example Full Workflow

### Scenario: Add Redis Caching Layer

**Phase 1: Planning (30 min)**
```bash
codex --readonly --high-thinking

> "I want to add Redis caching to improve API performance.
   Current stack: Python/Flask, PostgreSQL.
   Analyze the codebase and create an implementation plan."

[Codex explores, identifies cache points, proposes strategy]

> "What are the risks? What could go wrong?"
> "How will we handle cache invalidation?"
> "Save the plan to extras/docs/redis-implementation-plan.md"
```

**Phase 2: Implementation (1-2 hours)**
```bash
codex --minimal-thinking

> "Implement the Redis caching layer as planned in
   @extras/docs/redis-implementation-plan.md"

[Codex creates cache module, adds decorators, updates config]

> "Add tests for cache hit/miss scenarios"
> "Update documentation"
```

**Phase 3: Multi-AI Review (15 min)**
```bash
# Run parallel reviews
claude --readonly "Review @unstaged-changes:
  - Redis integration quality
  - Error handling
  - Performance impact" &

gemini -p "@unstaged-changes Review this Redis caching implementation.
  Focus on architecture and potential issues." &

# Use Copilot for GitHub-aware + security review
# (Using GPT-5 here for model diversity, but default Sonnet 4.5 is fine too)
COPILOT_MODEL=gpt-5 gh copilot suggest "Security review:
  - Redis connection security
  - Cache poisoning risks
  - Sensitive data in cache?" &

wait

# Collect feedback
# Claude (Sonnet 4.5): Suggests better error handling
# Gemini (2.0): Questions cache key naming strategy
# Copilot (GPT-5): Flags potential security issue with cache keys
```

**Phase 4: Iteration (30 min)**
```bash
codex --minimal-thinking

> "Address these review concerns:
   1. Improve error handling (Claude feedback)
   2. Refactor cache key naming (Gemini suggestion)
   3. Fix security issue with user data in cache keys (Copilot finding)"

[Codex makes improvements]

# Quick re-review if needed
claude --readonly "Quick review of fixes to cache implementation"
```

**Commit**
```bash
/commit --push
# Creates proper conventional commit with all context
```

## Tool Configuration Reference

### Codex CLI
```bash
# Planning mode
codex --readonly --high-thinking --model o3-plus

# Implementation mode
codex --minimal-thinking --model o1-plus

# Check current config
codex config show
```

### Claude Code
```bash
# Read-only mode (no file modifications)
claude --readonly "Review the implementation"

# Normal mode (default, can modify files)
claude "Implement the feature"
```

### Gemini CLI
```bash
# Always read-only by default for reviews
gemini -p "Review @unstaged-changes for architectural soundness"

# Can use file references
gemini -p "@src/auth.py Review this authentication code"
```

### Copilot CLI
```bash
# Default: Claude Sonnet 4.5 (same family as Claude Code)
gh copilot suggest "Review unstaged changes"

# Switch to GPT-5 for different model perspective
COPILOT_MODEL=gpt-5 gh copilot suggest "Review unstaged changes"

# PR review (ALWAYS use Copilot for this - native GitHub integration)
gh copilot pr review <number>                    # Uses Sonnet 4.5 (default, fine!)
COPILOT_MODEL=gpt-5 gh copilot pr review <number> # Or GPT-5 if you want

# Issue analysis (native GitHub context)
gh copilot issue analyze <number>

# GitHub Actions debugging (understands workflow context)
gh copilot suggest "Why is this workflow failing?" --file .github/workflows/ci.yml
```

**Copilot's GitHub Superpowers**:
- **Authenticated out of the box**: Uses your existing GitHub account, no API keys needed
- **Full repo context**: Understands your codebase, commit history, and project structure
- **Native PR/issue access**: Reads and analyzes PRs, issues, comments directly
- **GitHub Actions integration**: Debugs workflows with full context
- **Natural language GitHub ops**: "Show me recent failed Actions runs", "Summarize PR #123"
- **Model flexibility**: Defaults to Claude Sonnet 4.5, can switch to GPT-5 with `COPILOT_MODEL=gpt-5`

**Rule of thumb**: If the task involves GitHub (PRs, issues, Actions, releases), **use Copilot first**.

**Note on model overlap**: Copilot defaults to Claude Sonnet 4.5 (same model family as Claude Code). This is fine! The value is in Copilot's GitHub-native integration, not just the model. For purely model diversity in reviews, switch to `COPILOT_MODEL=gpt-5`.

## Workflow Variations

### Quick Iteration (Skip Planning)
For small changes where plan is obvious:
```
Phase 2 (Implementation) → Phase 3 (Review) → Phase 4 (Iterate) → Commit
```

### Deep Planning (Extended Phase 1)
For complex features:
```
Phase 1a (Exploration) → Phase 1b (Detailed Design) →
Phase 1c (Risk Analysis) → Phase 2 (Implementation) → ...
```

### Single-AI Fast Path
For trivial changes:
```
Codex (Implementation) → Claude (Quick Review) → Commit
```

### High-Stakes Full Review
For critical changes:
```
Phase 1 (Plan) → Peer Review Plan →
Phase 2 (Implement) → Phase 3 (3-AI Review) →
Phase 4 (Iterate) → Phase 3 (Re-review) → Commit
```

### GitHub-Centric Workflow
For PR reviews, issue triage, Actions debugging:
```
Copilot (GitHub Operations) → [Implementation if needed] → Copilot (PR Review)
```

**Example GitHub workflows:**

**PR Review**:
```bash
# Copilot handles the entire PR review natively
COPILOT_MODEL=gpt-5 gh copilot pr review 123

# If changes needed, implement with Codex
codex "Address PR feedback: @pr-comments"

# Copilot reviews the updates
COPILOT_MODEL=gpt-5 gh copilot pr review 123
```

**Issue Triage**:
```bash
# Copilot analyzes issue with full GitHub context
gh copilot issue analyze 456

# If complex strategy needed, consult Gemini
gemini -p "Strategic approach for @issue-456"

# Implement with Codex
codex "Implement solution for issue #456 per plan"

# Link PR to issue (Copilot understands GitHub conventions)
gh copilot suggest "Create PR that closes issue #456"
```

**GitHub Actions Debugging**:
```bash
# Copilot has native workflow context
gh copilot suggest "Debug failed workflow run" --file .github/workflows/ci.yml

# Shows recent runs, errors, suggests fixes
# No other AI has this deep GitHub Actions integration
```

## Troubleshooting

### Issue: Conflicting Feedback from Reviewers
**Solution**:
- Trust your judgment as final authority
- If uncertain, ask for clarification
- Consider context (one AI might miss broader context)
- Document why you chose one approach over another

### Issue: Codex Deviates from Plan
**Solution**:
- Reference the plan file explicitly: `@PLAN.md`
- Be more prescriptive in prompts
- Break down into smaller steps
- Switch back to high-thinking if needed

### Issue: Reviews are Too Generic
**Solution**:
- Be specific about what to review
- Provide context about concerns
- Ask focused questions
- Share the original plan for context

### Issue: Too Many Review Cycles
**Solution**:
- Set iteration limits (max 2 cycles)
- Prioritize critical feedback only
- Consider if changes are truly needed
- Document intentional deviations from suggestions

## Metrics to Track

Consider tracking these over time:
- Time spent in each phase
- Number of review cycles before commit
- Issues caught by each AI
- False positives (suggestions that weren't helpful)
- Actual bugs in production (validation of process)

## Related Documentation

- [Git Worktrees](./git-worktrees.md) - Parallel development workflow
- [Security Guidelines](./security.md) - Security review checklist
- [Ansible Architecture](./ansible-architecture.md) - Codebase structure

## Evolution of This Workflow

This is a living document. As you use this workflow, note:
- What works well
- What's inefficient
- What could be automated
- New patterns that emerge

Update this document accordingly.
