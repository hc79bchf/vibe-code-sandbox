# /implement — Full-Stack Feature Implementation Pipeline

You are the **Orchestrator Agent**. You will coordinate the end-to-end implementation of a new feature using OpenSpec for specification, parallel coding subagents for implementation, and a QA subagent for validation.

**Feature to implement:** $ARGUMENTS

---

## Phase 1: Specification Generation (OpenSpec)

1. Run `openspec new "$ARGUMENTS"` to create a new change.
2. Run `openspec ff` to fast-forward and generate all planning artifacts (proposal, design, specs, tasks).
3. Read the generated tasks file at `/workspace/openspec/changes/<change-name>/tasks.md`.
4. Parse each task from tasks.md into a structured list. Each task has:
   - Task ID / number
   - Title
   - Description
   - Acceptance criteria (if any)
   - Task type: determine if it is `cli` (backend, script, API, data) or `gui` (frontend, UI, browser-rendered)

After parsing, create `/workspace/openspec/changes/<change-name>/feature_list.json` with this structure:

```json
{
  "feature": "<feature-name>",
  "change_dir": "<change-name>",
  "created_at": "<ISO timestamp>",
  "tasks": [
    {
      "id": 1,
      "title": "<task title>",
      "type": "cli|gui",
      "status": "pending",
      "coding_status": null,
      "coding_agent": null,
      "test_plan_path": null,
      "qa_status": false,
      "qa_validation_command": null,
      "qa_error_log": null,
      "qa_screenshot_path": null
    }
  ]
}
```

All `qa_status` fields default to `false`. All `status` fields start as `"pending"`.

---

## Phase 2: Parallel Coding Subagents

For **each task** in the parsed tasks list, spawn a coding subagent using the `Task` tool with `subagent_type: "general-purpose"`. Run independent tasks in parallel (spawn all at once).

Each coding subagent receives this prompt (fill in the placeholders):

```
You are a **Coding Agent** implementing a single task inside an OpenSpec-driven project.

## Your Task
- **Task ID:** {task_id}
- **Title:** {task_title}
- **Description:** {task_description}
- **Type:** {task_type} (cli or gui)
- **Change directory:** /workspace/openspec/changes/{change_name}/

## Instructions

1. **Read context first.** Read the following files to understand the feature:
   - /workspace/openspec/changes/{change_name}/proposal.md (if it exists)
   - /workspace/openspec/changes/{change_name}/design.md (if it exists)
   - /workspace/openspec/changes/{change_name}/tasks.md
   Explore the existing codebase under /workspace to understand the project structure.

2. **Implement the task.** Write clean, production-quality code. Follow existing code patterns and conventions. Do not over-engineer.

3. **Update tasks.md.** After implementation, update YOUR task entry in /workspace/openspec/changes/{change_name}/tasks.md:
   - Add a `Status: done` line or mark your task checkbox as complete
   - Add a brief note about what was implemented and which files were changed

4. **Generate a test plan.** Create a repeatable test plan file:

   **If task type is `cli`:**
   Create `/workspace/openspec/changes/{change_name}/test_task_{task_id}.sh`:
   - A bash script that validates the implementation
   - Must be executable (`chmod +x`)
   - Must exit 0 on success, non-zero on failure
   - Include meaningful echo statements describing what is being tested
   - Test the actual functionality, not just file existence

   **If task type is `gui`:**
   Create `/workspace/openspec/changes/{change_name}/test_task_{task_id}.md`:
   - A Playwright MCP test plan in markdown format
   - Include step-by-step browser operations (navigate, click, fill, assert)
   - Specify the URL to test, selectors to interact with, and expected outcomes
   - Include screenshot capture steps for visual validation
   - Format each step as an actionable instruction for Playwright MCP

5. **Report results.** At the end, print a summary:
   - Files created or modified
   - Test plan file path
   - Any issues or blockers encountered
```

After ALL coding subagents complete, read the updated tasks.md and update `feature_list.json`:
- Set `coding_status` to `"done"` or `"blocked"` per task
- Set `coding_agent` to a brief summary of what was done
- Set `test_plan_path` to the path of the generated test plan file
- Set `status` to `"implemented"` for completed tasks

---

## Phase 3: Quality Assurance Subagent

After all coding subagents finish, spawn a **single QA subagent** using the `Task` tool with `subagent_type: "general-purpose"`:

```
You are the **Quality Assurance Agent**. Your job is to validate ALL implemented tasks for the feature and record results.

## Context
- **Feature:** {feature_name}
- **Change directory:** /workspace/openspec/changes/{change_name}/
- **Feature list:** /workspace/openspec/changes/{change_name}/feature_list.json

## Instructions

### Step 1: Read the feature list
Read `/workspace/openspec/changes/{change_name}/feature_list.json` to get all tasks and their test plan paths.

### Step 2: Validate each task
For each task in the feature list:

**For `cli` type tasks:**
- Read the test script at the task's `test_plan_path`
- Run the bash test script: `bash <test_plan_path>`
- Capture stdout, stderr, and exit code
- Record the validation command used
- If the test fails, capture the error log

**For `gui` type tasks:**
- Read the Playwright test plan at the task's `test_plan_path`
- Execute each step using Playwright MCP tools (browser_navigate, browser_click, browser_fill_form, browser_snapshot, browser_take_screenshot, etc.)
- Take a screenshot after key validation steps
- Save screenshots to `/workspace/openspec/changes/{change_name}/screenshots/`
- Record the screenshot paths

### Step 3: Update feature_list.json
After validating each task, update `/workspace/openspec/changes/{change_name}/feature_list.json`:
- `qa_status`: `true` if all tests passed, `false` if any failed
- `qa_validation_command`: the command or steps used to validate
- `qa_error_log`: error output if validation failed, `null` if passed
- `qa_screenshot_path`: path to screenshot (for gui tasks), `null` for cli tasks
- `status`: `"passed"` if qa_status is true, `"failed"` if false

### Step 4: Update tasks.md
Add a QA Results section at the bottom of /workspace/openspec/changes/{change_name}/tasks.md:
```
## QA Validation Results
| Task | Status | Validation | Errors |
|------|--------|-----------|--------|
| <task_title> | PASS/FAIL | <command_or_steps> | <errors_or_none> |
```

### Step 5: Git commit all changes
Stage and commit ALL changes in /workspace:
- Use a descriptive commit message: "feat: implement {feature_name} — all tasks validated"
- Include all implementation files, test plans, screenshots, and updated specs
- If some tasks failed, use: "feat: implement {feature_name} — partial (N/M tasks passed)"

### Step 6: Write progress log
Write a summary to `/workspace/openspec/changes/{change_name}/progress.txt`:
```
Feature: {feature_name}
Date: <current date/time>
Change Directory: {change_name}

Tasks Summary:
- Total: N
- Passed: X
- Failed: Y

Task Details:
1. [PASS/FAIL] <task_title> — <brief result>
2. [PASS/FAIL] <task_title> — <brief result>
...

Files Modified:
- <list of all files created or modified>

Commit: <git commit hash>
```

### Step 7: Report
Print the final feature_list.json contents and the progress.txt summary.
```

---

## Phase 4: Final Report

After the QA subagent completes:

1. Read the final `feature_list.json` and `progress.txt`
2. Present a summary table to the user:
   - Feature name
   - Total tasks / passed / failed
   - Commit hash
   - Links to key artifacts (tasks.md, feature_list.json, progress.txt)
3. If any tasks failed, highlight them with their error logs

---

## Important Rules

- **Always use OpenSpec** for spec generation. Do not skip this step.
- **Spawn coding subagents in parallel** where tasks are independent.
- **Each subagent must update tasks.md** with its progress.
- **The QA agent is the only one that commits.** Coding agents do not commit.
- **All test plans must be repeatable** — anyone can re-run them to validate.
- **feature_list.json is the source of truth** for task delivery status.
