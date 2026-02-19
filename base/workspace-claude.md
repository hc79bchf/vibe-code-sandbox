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
