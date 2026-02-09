/**
 * Vibe Guard — Red/Green test suite (Vitest)
 *
 * Tests Layer 1 Biome (JS/TS linter) and Layer 3 pre-commit integration for JS.
 *
 * Red tests  = bad JS that MUST be caught (non-zero exit code)
 * Green tests = clean JS that MUST pass (zero exit code)
 */

import { describe, it, expect, beforeEach, afterEach } from "vitest";
import { execSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

function tmpDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "vibe_guard_js_"));
}

function run(cmd, cwd) {
  try {
    const out = execSync(cmd, { cwd, encoding: "utf8", stdio: "pipe" });
    return { code: 0, stdout: out, stderr: "" };
  } catch (e) {
    return { code: e.status, stdout: e.stdout || "", stderr: e.stderr || "" };
  }
}

function writeFile(dir, name, content) {
  // Trim leading/trailing newlines so Biome formatter is happy
  fs.writeFileSync(
    path.join(dir, name),
    content.replace(/^ {4}/gm, "").replace(/^\n/, "").replace(/\n\s*$/, "\n"),
  );
}

// =========================================================================
// Layer 1 — Biome (JS/TS linter)
// =========================================================================

describe("Biome Red Tests", () => {
  let dir;
  beforeEach(() => { dir = tmpDir(); });
  afterEach(() => { fs.rmSync(dir, { recursive: true, force: true }); });

  it("catches debugger statements", () => {
    writeFile(dir, "bad.js", `
    const x = 1;
    debugger;
    console.log(x);
    `);
    const r = run("biome check bad.js", dir);
    expect(r.code).not.toBe(0);
    expect(r.stdout + r.stderr).toContain("noDebugger");
  });

  it("catches eval() usage", () => {
    writeFile(dir, "bad.js", `
    function run(code) {
    \teval(code);
    }
    run("1+1");
    `);
    const r = run("biome check bad.js", dir);
    expect(r.code).not.toBe(0);
    expect(r.stdout + r.stderr).toContain("noGlobalEval");
  });

  it("catches duplicate function parameters", () => {
    writeFile(dir, "bad.js", `
    function add(a, b, a) {
    \treturn a + b;
    }
    add(1, 2, 3);
    `);
    const r = run("biome check bad.js", dir);
    expect(r.code).not.toBe(0);
    expect(r.stdout + r.stderr).toContain("noDuplicateParameters");
  });

  it("catches unreachable code", () => {
    writeFile(dir, "bad.js", `
    function getValue() {
    \treturn 42;
    \tconsole.log("unreachable");
    }
    getValue();
    `);
    const r = run("biome check bad.js", dir);
    expect(r.code).not.toBe(0);
    expect(r.stdout + r.stderr).toContain("noUnreachable");
  });
});

describe("Biome Green Tests", () => {
  let dir;
  beforeEach(() => { dir = tmpDir(); });
  afterEach(() => { fs.rmSync(dir, { recursive: true, force: true }); });

  it("passes clean function", () => {
    writeFile(dir, "clean.js", `
    function add(a, b) {
    \treturn a + b;
    }
    console.log(add(1, 2));
    `);
    const r = run("biome check clean.js", dir);
    expect(r.code).toBe(0);
  });

  it("passes const/let declarations", () => {
    writeFile(dir, "clean.js", `
    const PI = 3.14159;
    let count = 0;
    count += 1;
    console.log(PI, count);
    `);
    const r = run("biome check clean.js", dir);
    expect(r.code).toBe(0);
  });

  it("passes async/await code", () => {
    writeFile(dir, "clean.js", `
    async function fetchData(url) {
    \tconst response = await fetch(url);
    \treturn response.json();
    }
    fetchData("https://example.com");
    `);
    const r = run("biome check clean.js", dir);
    expect(r.code).toBe(0);
  });

  it("passes class with methods", () => {
    writeFile(dir, "clean.js", `
    class Counter {
    \tconstructor() {
    \t\tthis.value = 0;
    \t}
    \tincrement() {
    \t\tthis.value += 1;
    \t\treturn this;
    \t}
    }
    const c = new Counter();
    c.increment();
    `);
    const r = run("biome check clean.js", dir);
    expect(r.code).toBe(0);
  });
});

// =========================================================================
// Layer 3 — Pre-commit integration for JS files
// =========================================================================

describe("Pre-commit JS Integration", () => {
  let dir;

  beforeEach(() => {
    dir = tmpDir();
    // Init git repo on non-master branch
    execSync("git init && git checkout -b test-branch", { cwd: dir, stdio: "pipe" });
    execSync('git config user.email "t@t.com" && git config user.name "T"', { cwd: dir, stdio: "pipe" });

    // Copy pre-commit config and install
    const home = os.homedir();
    const configSrc = path.join(home, "pre-commit-config.yaml");
    if (fs.existsSync(configSrc)) {
      fs.copyFileSync(configSrc, path.join(dir, ".pre-commit-config.yaml"));
    }
    execSync("git add . && git commit -m init --no-verify", { cwd: dir, stdio: "pipe" });
    execSync("pre-commit install", { cwd: dir, stdio: "pipe" });
  });

  afterEach(() => {
    fs.rmSync(dir, { recursive: true, force: true });
  });

  it("RED: blocks JS with debugger via pre-commit", () => {
    writeFile(dir, "bad.js", `
    const x = 1;
    debugger;
    console.log(x);
    `);
    execSync("git add bad.js", { cwd: dir, stdio: "pipe" });
    const r = run("git commit -m 'add bad js'", dir);
    expect(r.code).not.toBe(0);
  });

  it("GREEN: allows clean JS via pre-commit", () => {
    writeFile(dir, "clean.js", `
    function greet(name) {
    \treturn name.toUpperCase();
    }
    console.log(greet("world"));
    `);
    execSync("git add clean.js", { cwd: dir, stdio: "pipe" });
    const r = run("git commit -m 'add clean js'", dir);
    expect(r.code).toBe(0);
  });
});

// =========================================================================
// Tool availability
// =========================================================================

describe("Tool Availability", () => {
  it("biome is installed", () => {
    const r = run("biome --version");
    expect(r.code).toBe(0);
  });

  it("ruff is installed", () => {
    const r = run("ruff --version");
    expect(r.code).toBe(0);
  });

  it("gitleaks is installed", () => {
    const r = run("gitleaks version");
    expect(r.code).toBe(0);
  });

  it("trivy is installed", () => {
    const r = run("trivy --version");
    expect(r.code).toBe(0);
  });

  it("pre-commit is installed", () => {
    const r = run("pre-commit --version");
    expect(r.code).toBe(0);
  });
});
