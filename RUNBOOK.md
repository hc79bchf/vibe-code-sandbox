# Vibe Guard Runbook

Operational guide for the Vibe Guard 3-layer auto-scan system inside sandbox containers.

## Activation

Vibe Guard activates automatically when the sandbox container starts, if `/workspace` is a git repo. The entrypoint script (`~/entrypoint.sh`) handles this on every container boot:

1. Copies `.pre-commit-config.yaml` to your project (if not already present)
2. Installs git hooks via `pre-commit install`
3. Runs an initial Trivy vulnerability scan
4. Runs an initial Gitleaks secret scan

If the workspace is not yet a git repo, Vibe Guard is skipped. You can activate it manually later:

```bash
cd /workspace
git init
~/setup-vibe-guard.sh
```

On subsequent container restarts, the entrypoint detects that hooks are already installed and skips re-setup.

## Deactivation

To disable Vibe Guard hooks for a project:

```bash
# Inside the container
cd /workspace
~/disable-vibe-guard.sh
```

This will:
1. Uninstall pre-commit hooks (commits no longer trigger auto-scans)
2. Leave `.pre-commit-config.yaml` in place for easy re-activation
3. Keep all tools available for manual use (`ruff`, `biome`, `trivy`, `gitleaks`)

To re-enable at any time:

```bash
~/setup-vibe-guard.sh
```

## What Happens on Every Commit

After activation, every `git commit` runs these checks automatically:

```
git commit -m "your message"
  |
  +-- Layer 1: Ruff (Python)
  |     - Checks .py files for lint errors
  |     - Auto-fixes imports, formatting, style issues
  |     - Blocks on: undefined names, unsafe comparisons
  |
  +-- Layer 1: Biome (JS/TS)
  |     - Checks .js/.ts/.jsx/.tsx files
  |     - Auto-fixes formatting and style
  |     - Blocks on: debugger, eval(), duplicate params, var usage
  |
  +-- Layer 2: Gitleaks
  |     - Scans staged files for hardcoded secrets
  |     - Blocks on: API keys, tokens, passwords, AWS credentials
  |
  +-- Layer 3: no-commit-to-branch
  |     - Blocks direct commits to master/main
  |
  +-- Layer 3: check-added-large-files
  |     - Blocks files larger than 500KB
  |
  +-- Layer 3: detect-private-key
        - Blocks private key files (.pem, etc.)
```

If any check fails, the commit is blocked. Fix the issue and retry.

## Auto-Fix Workflow

When Ruff or Biome auto-fix files, the commit will fail because the working tree was modified. This is expected:

```bash
git commit -m "feat: add feature"    # Fails — files were auto-fixed
git add -A                           # Stage the auto-fixed changes
git commit -m "feat: add feature"    # Passes
```

## Manual Scans

Run any tool independently without committing:

### Python Linting (Ruff)

```bash
# Check for errors
ruff check .

# Check and auto-fix
ruff check --fix .

# Format code
ruff format .
```

### JS/TS Linting (Biome)

```bash
# Check for errors
biome check .

# Check and auto-fix
biome check --write .
```

### Vulnerability Scanning (Trivy)

```bash
# Scan for vulnerabilities and secrets (HIGH + CRITICAL only)
trivy fs . --scanners vuln,secret --severity HIGH,CRITICAL

# Scan dependencies only
trivy fs . --scanners vuln

# Scan for secrets only
trivy fs . --scanners secret
```

### Secret Detection (Gitleaks)

```bash
# Scan git history
gitleaks detect --source .

# Scan all files (including untracked)
gitleaks detect --source . --no-git -v

# Verbose output with findings
gitleaks detect --source . -v
```

## Pre-commit Hook Configuration

The default hook config is at `~/pre-commit-config.yaml` and gets copied to `.pre-commit-config.yaml` in your project. Current hooks:

| Hook | Source | Action |
|------|--------|--------|
| `ruff` | astral-sh/ruff-pre-commit v0.9.6 | Lint + auto-fix Python with `--fix` |
| `biome-check` | biomejs/pre-commit v0.6.1 | Lint + auto-fix JS/TS |
| `gitleaks` | gitleaks/gitleaks v8.21.2 | Block hardcoded secrets |
| `no-commit-to-branch` | pre-commit-hooks v5.0.0 | Block commits to master/main |
| `check-added-large-files` | pre-commit-hooks v5.0.0 | Block files > 500KB |
| `detect-private-key` | pre-commit-hooks v5.0.0 | Block private key files |

### Customizing Hooks

Edit `.pre-commit-config.yaml` in your project to add or remove hooks:

```bash
# After editing the config, reinstall hooks
pre-commit install

# Test all hooks against staged files
pre-commit run --all-files
```

## Troubleshooting

### Commit blocked by Ruff but code looks correct

Ruff may flag issues that need `--unsafe-fixes` to resolve automatically:

```bash
ruff check --fix --unsafe-fixes .
git add -A
git commit -m "your message"
```

### Commit blocked by no-commit-to-branch

You're on master/main. Create a feature branch:

```bash
git checkout -b feature/your-feature
git commit -m "your message"
```

### Gitleaks false positive

Add a `.gitleaksignore` file to your project with the fingerprint of the false positive:

```bash
# .gitleaksignore
red_secrets.py:generic-api-key:6
```

### Pre-commit hooks not running

Verify hooks are installed:

```bash
pre-commit install
ls -la .git/hooks/pre-commit
```

### Updating hook versions

```bash
pre-commit autoupdate
pre-commit install
```

### Bypassing hooks (emergency only)

```bash
git commit -m "emergency fix" --no-verify
```

Use sparingly. This skips all checks.
