"""
Vibe Guard — Red/Green test suite (Pytest)

Tests each layer of the Vibe Guard security scanning system:
  Layer 1: Ruff (Python linter)
  Layer 2: Gitleaks (secret detection), Trivy (vulnerability scanner)
  Layer 3: pre-commit hooks (private key, large files, branch protection)

Red tests  = bad input that MUST be caught (non-zero exit code)
Green tests = clean input that MUST pass (zero exit code)
"""

import os
import shutil
import subprocess
import tempfile
import textwrap

import pytest


@pytest.fixture()
def work_dir():
    """Create a temporary directory for test artifacts."""
    d = tempfile.mkdtemp(prefix="vibe_guard_test_")
    yield d
    shutil.rmtree(d, ignore_errors=True)


@pytest.fixture()
def git_repo(work_dir):
    """Create a temporary git repo with Vibe Guard pre-commit hooks installed."""
    subprocess.run(["git", "init"], cwd=work_dir, check=True, capture_output=True)
    subprocess.run(
        ["git", "config", "user.email", "test@test.com"],
        cwd=work_dir, check=True, capture_output=True,
    )
    subprocess.run(
        ["git", "config", "user.name", "Test"],
        cwd=work_dir, check=True, capture_output=True,
    )
    subprocess.run(
        ["git", "checkout", "-b", "test-branch"],
        cwd=work_dir, check=True, capture_output=True,
    )
    # Copy pre-commit config and install hooks
    home = os.path.expanduser("~")
    config_src = os.path.join(home, "pre-commit-config.yaml")
    if os.path.exists(config_src):
        shutil.copy(config_src, os.path.join(work_dir, ".pre-commit-config.yaml"))
    subprocess.run(
        ["pre-commit", "install"],
        cwd=work_dir, check=True, capture_output=True,
    )
    # Initial commit so hooks run on subsequent commits
    with open(os.path.join(work_dir, ".pre-commit-config.yaml"), "a"):
        pass
    subprocess.run(["git", "add", "."], cwd=work_dir, check=True, capture_output=True)
    subprocess.run(
        ["git", "commit", "-m", "init", "--no-verify"],
        cwd=work_dir, check=True, capture_output=True,
    )
    yield work_dir


def _write(path, content):
    with open(path, "w") as f:
        f.write(textwrap.dedent(content))


def _run(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


# =========================================================================
# Layer 1 — Ruff (Python linter)
# =========================================================================

class TestRuffRed:
    """Red tests: Ruff MUST report errors for bad Python code."""

    def test_undefined_variable(self, work_dir):
        _write(os.path.join(work_dir, "bad.py"), """\
            def foo():
                return undefined_var
        """)
        r = _run(["ruff", "check", "bad.py"], cwd=work_dir)
        assert r.returncode != 0, f"Ruff should fail on undefined name\n{r.stdout}"
        assert "F821" in r.stdout

    def test_unused_import(self, work_dir):
        _write(os.path.join(work_dir, "bad.py"), """\
            import os
            import sys
            import json

            def greet():
                return "hello"
        """)
        r = _run(["ruff", "check", "bad.py"], cwd=work_dir)
        assert r.returncode != 0, f"Ruff should fail on unused imports\n{r.stdout}"
        assert "F401" in r.stdout

    def test_comparison_to_true(self, work_dir):
        _write(os.path.join(work_dir, "bad.py"), """\
            x = 1
            if x == True:
                pass
        """)
        r = _run(["ruff", "check", "bad.py"], cwd=work_dir)
        assert r.returncode != 0
        assert "E712" in r.stdout

    def test_unused_variable(self, work_dir):
        _write(os.path.join(work_dir, "bad.py"), """\
            def compute():
                result = 42
                return None
        """)
        r = _run(["ruff", "check", "bad.py"], cwd=work_dir)
        assert r.returncode != 0
        assert "F841" in r.stdout


class TestRuffGreen:
    """Green tests: Ruff MUST pass for clean Python code."""

    def test_clean_function(self, work_dir):
        _write(os.path.join(work_dir, "clean.py"), """\
            def add(a: int, b: int) -> int:
                return a + b
        """)
        r = _run(["ruff", "check", "clean.py"], cwd=work_dir)
        assert r.returncode == 0, f"Ruff should pass clean code\n{r.stdout}"

    def test_clean_with_imports(self, work_dir):
        _write(os.path.join(work_dir, "clean.py"), """\
            import os

            def get_cwd() -> str:
                return os.getcwd()
        """)
        r = _run(["ruff", "check", "clean.py"], cwd=work_dir)
        assert r.returncode == 0, f"Ruff should pass used imports\n{r.stdout}"

    def test_clean_class(self, work_dir):
        _write(os.path.join(work_dir, "clean.py"), """\
            class Calculator:
                def __init__(self, value: int = 0) -> None:
                    self.value = value

                def add(self, n: int) -> "Calculator":
                    self.value += n
                    return self
        """)
        r = _run(["ruff", "check", "clean.py"], cwd=work_dir)
        assert r.returncode == 0


# =========================================================================
# Layer 2 — Gitleaks (secret detection)
# =========================================================================

class TestGitleaksRed:
    """Red tests: Gitleaks MUST detect hardcoded secrets."""

    def test_aws_access_key(self, work_dir):
        _write(os.path.join(work_dir, "config.py"), """\
            AWS_ACCESS_KEY_ID = "AKIAZ5GMXQR7AZPWQ4X9"
            AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYzExAmPlEkEy"
        """)
        r = _run(["gitleaks", "detect", "--source", work_dir, "--no-git", "-v"])
        assert r.returncode != 0, f"Gitleaks should catch AWS key\n{r.stdout}"

    def test_github_token(self, work_dir):
        _write(os.path.join(work_dir, "config.py"), """\
            GITHUB_TOKEN = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef12"
        """)
        r = _run(["gitleaks", "detect", "--source", work_dir, "--no-git", "-v"])
        assert r.returncode != 0, f"Gitleaks should catch GitHub token\n{r.stdout}"

    def test_generic_api_key(self, work_dir):
        _write(os.path.join(work_dir, "config.py"), """\
            api_key = "sk-proj-abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmn"
        """)
        r = _run(["gitleaks", "detect", "--source", work_dir, "--no-git", "-v"])
        assert r.returncode != 0, f"Gitleaks should catch generic API key\n{r.stdout}"


class TestGitleaksGreen:
    """Green tests: Gitleaks MUST pass code without secrets."""

    def test_env_var_reference(self, work_dir):
        _write(os.path.join(work_dir, "config.py"), """\
            import os
            API_KEY = os.environ.get("API_KEY", "")
        """)
        r = _run(["gitleaks", "detect", "--source", work_dir, "--no-git", "-v"])
        assert r.returncode == 0, f"Gitleaks should pass env var references\n{r.stdout}"

    def test_placeholder_values(self, work_dir):
        _write(os.path.join(work_dir, "config.py"), """\
            DATABASE_URL = "sqlite:///local.db"
            DEBUG = True
        """)
        r = _run(["gitleaks", "detect", "--source", work_dir, "--no-git", "-v"])
        assert r.returncode == 0


# =========================================================================
# Layer 2 — Trivy (vulnerability + secret scanner)
# =========================================================================

class TestTrivyGreen:
    """Green tests: Trivy MUST pass on a clean directory."""

    def test_no_vulnerabilities_empty_dir(self, work_dir):
        r = _run(
            ["trivy", "fs", work_dir, "--scanners", "secret",
             "--severity", "HIGH,CRITICAL", "--exit-code", "1"],
        )
        assert r.returncode == 0, f"Trivy should pass on empty dir\n{r.stdout}"

    def test_no_secrets_in_clean_code(self, work_dir):
        _write(os.path.join(work_dir, "app.py"), """\
            import os
            DB = os.environ.get("DB_URL", "sqlite:///test.db")
        """)
        r = _run(
            ["trivy", "fs", work_dir, "--scanners", "secret",
             "--severity", "HIGH,CRITICAL", "--exit-code", "1"],
        )
        assert r.returncode == 0


# =========================================================================
# Layer 3 — Pre-commit hooks (integrated checks)
# =========================================================================

class TestPreCommitRed:
    """Red tests: pre-commit hooks MUST block bad commits."""

    def test_ruff_blocks_commit(self, git_repo):
        _write(os.path.join(git_repo, "bad.py"), """\
            def foo():
                return undefined_var
        """)
        subprocess.run(["git", "add", "bad.py"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "bad python"], cwd=git_repo)
        assert r.returncode != 0, "Pre-commit should block bad Python code"

    def test_private_key_blocks_commit(self, git_repo):
        _write(os.path.join(git_repo, "server.pem"), """\
            -----BEGIN RSA PRIVATE KEY-----
            MIIEpAIBAAKCAQEA0Z3VS5JJcds3xfn/ygWyF8PbnGy0AHB7
            -----END RSA PRIVATE KEY-----
        """)
        subprocess.run(["git", "add", "server.pem"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "add key"], cwd=git_repo)
        assert r.returncode != 0, "Pre-commit should block private key files"

    def test_large_file_blocks_commit(self, git_repo):
        large_path = os.path.join(git_repo, "big.bin")
        with open(large_path, "wb") as f:
            f.write(b"\0" * (600 * 1024))  # 600 KB > 500 KB limit
        subprocess.run(["git", "add", "big.bin"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "add big file"], cwd=git_repo)
        assert r.returncode != 0, "Pre-commit should block large files"

    def test_master_branch_blocks_commit(self, work_dir):
        """Commits to master/main should be blocked by no-commit-to-branch."""
        subprocess.run(["git", "init"], cwd=work_dir, check=True, capture_output=True)
        subprocess.run(
            ["git", "config", "user.email", "t@t.com"],
            cwd=work_dir, check=True, capture_output=True,
        )
        subprocess.run(
            ["git", "config", "user.name", "T"],
            cwd=work_dir, check=True, capture_output=True,
        )
        # Stay on master (default branch)
        home = os.path.expanduser("~")
        config_src = os.path.join(home, "pre-commit-config.yaml")
        if os.path.exists(config_src):
            shutil.copy(config_src, os.path.join(work_dir, ".pre-commit-config.yaml"))
        subprocess.run(["git", "add", "."], cwd=work_dir, check=True, capture_output=True)
        subprocess.run(
            ["git", "commit", "-m", "init", "--no-verify"],
            cwd=work_dir, check=True, capture_output=True,
        )
        subprocess.run(["pre-commit", "install"], cwd=work_dir, check=True, capture_output=True)
        _write(os.path.join(work_dir, "readme.txt"), "hello")
        subprocess.run(["git", "add", "readme.txt"], cwd=work_dir, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "commit on master"], cwd=work_dir)
        assert r.returncode != 0, "Pre-commit should block commits to master"


class TestPreCommitGreen:
    """Green tests: pre-commit hooks MUST allow clean commits."""

    def test_clean_python_commits(self, git_repo):
        _write(os.path.join(git_repo, "clean.py"), """\
            def add(a: int, b: int) -> int:
                return a + b
        """)
        subprocess.run(["git", "add", "clean.py"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "add clean python"], cwd=git_repo)
        assert r.returncode == 0, f"Clean Python should commit successfully\n{r.stderr}"

    def test_clean_config_commits(self, git_repo):
        _write(os.path.join(git_repo, "config.py"), """\
            import os

            DB_URL = os.environ.get("DATABASE_URL", "sqlite:///local.db")
        """)
        subprocess.run(["git", "add", "config.py"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "add clean config"], cwd=git_repo)
        assert r.returncode == 0, f"Clean config should commit successfully\n{r.stderr}"

    def test_small_file_commits(self, git_repo):
        small_path = os.path.join(git_repo, "data.txt")
        with open(small_path, "w") as f:
            f.write("small file content\n" * 100)
        subprocess.run(["git", "add", "data.txt"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "add small file"], cwd=git_repo)
        assert r.returncode == 0, f"Small file should commit successfully\n{r.stderr}"


# =========================================================================
# Tool availability checks
# =========================================================================

class TestToolsAvailable:
    """Verify all Vibe Guard tools are installed and accessible."""

    @pytest.mark.parametrize("cmd,flag", [
        (["ruff", "--version"], None),
        (["biome", "--version"], None),
        (["trivy", "--version"], None),
        (["gitleaks", "version"], None),
        (["pre-commit", "--version"], None),
    ])
    def test_tool_installed(self, cmd, flag):
        r = _run(cmd)
        assert r.returncode == 0, f"{cmd[0]} not available: {r.stderr}"


# =========================================================================
# Helper script tests
# =========================================================================

class TestHelperScripts:
    """Verify setup and disable scripts exist and are executable."""

    @pytest.mark.parametrize("script", [
        os.path.expanduser("~/setup-vibe-guard.sh"),
        os.path.expanduser("~/disable-vibe-guard.sh"),
        os.path.expanduser("~/entrypoint.sh"),
        os.path.expanduser("~/setup-plugins.sh"),
    ])
    def test_script_exists_and_executable(self, script):
        assert os.path.isfile(script), f"{script} not found"
        assert os.access(script, os.X_OK), f"{script} not executable"

    def test_disable_then_reenable(self, git_repo):
        """Disable Vibe Guard, verify commits bypass hooks, re-enable."""
        # Disable
        r = _run(["bash", os.path.expanduser("~/disable-vibe-guard.sh")], cwd=git_repo)
        assert r.returncode == 0, f"disable script failed\n{r.stderr}"

        # Bad code should now commit (hooks disabled)
        _write(os.path.join(git_repo, "bad.py"), """\
            def foo():
                return undefined_var
        """)
        subprocess.run(["git", "add", "bad.py"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "bad code with guard disabled"], cwd=git_repo)
        assert r.returncode == 0, f"Commit should pass with Vibe Guard disabled\n{r.stderr}"

        # Re-enable
        r = _run(["bash", os.path.expanduser("~/setup-vibe-guard.sh")], cwd=git_repo)
        assert r.returncode == 0, f"setup script failed\n{r.stderr}"

        # Bad code should now be blocked again
        _write(os.path.join(git_repo, "bad2.py"), """\
            def bar():
                return another_undefined
        """)
        subprocess.run(["git", "add", "bad2.py"], cwd=git_repo, check=True, capture_output=True)
        r = _run(["git", "commit", "-m", "bad code with guard re-enabled"], cwd=git_repo)
        assert r.returncode != 0, "Commit should fail after re-enabling Vibe Guard"
