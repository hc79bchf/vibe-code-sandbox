# Sandbox Development Guidelines

## Spec-Driven Development with OpenSpec

Use OpenSpec for all feature work, bug fixes, and refactoring. OpenSpec is pre-installed and auto-initialized in this sandbox.

### Workflow

1. **Before writing code**, create a spec: `/opsx:new <feature-or-change-name>`
2. **Generate planning artifacts** (proposal, design, specs, tasks): `/opsx:ff`
3. **Implement from the task list**: `/opsx:apply`
4. **Verify implementation matches spec**: `/opsx:verify`
5. **Merge specs and archive**: `/opsx:sync` then `/opsx:archive`

### When to Use OpenSpec

- New features or functionality
- Bug fixes that change behavior
- Refactoring that touches multiple files
- Any change where requirements should be documented

### Quick Reference

| Command | Purpose |
|---------|---------|
| `/opsx:explore` | Investigate ideas before committing |
| `/opsx:new` | Start a new change with spec |
| `/opsx:ff` | Fast-forward: generate all planning artifacts |
| `/opsx:apply` | Implement tasks from the spec |
| `/opsx:verify` | Validate implementation matches spec |
| `/opsx:sync` | Merge delta specs into main specs |
| `/opsx:archive` | Archive completed change |

### Specs Directory

All specifications live in `openspec/specs/` (source of truth) and per-change artifacts in `openspec/changes/<change-name>/`.

---

## Automated Feature Implementation

Use `/implement <feature-name>` for fully automated, multi-agent feature implementation.

### What It Does

1. **Spec Generation** — Uses OpenSpec to create detailed specifications and tasks.md
2. **Parallel Coding** — Spawns one coding subagent per task, working in parallel
3. **Test Plan Generation** — Each coding agent produces repeatable test plans:
   - CLI tasks: executable bash test scripts (`test_task_N.sh`)
   - GUI tasks: Playwright MCP operation test plans (`test_task_N.md`)
4. **QA Validation** — A QA subagent runs all test plans and records results
5. **Structured Delivery** — Updates `feature_list.json` with pass/fail status per task
6. **Auto-Commit** — QA agent commits all changes and writes `progress.txt`

### Usage

```
/implement add user authentication with JWT tokens
/implement create REST API for product catalog
/implement build dashboard with real-time charts
```

### Output Artifacts

After `/implement` completes, find these in `openspec/changes/<change-name>/`:

| File | Purpose |
|------|---------|
| `tasks.md` | Task list with implementation notes and QA results |
| `feature_list.json` | Structured delivery list with pass/fail per task |
| `test_task_N.sh` | Bash test scripts for CLI tasks |
| `test_task_N.md` | Playwright test plans for GUI tasks |
| `screenshots/` | UI screenshots captured during QA (GUI tasks) |
| `progress.txt` | Final summary log with commit hash |
