---
name: commit-message
description: Review staged changes and create a commit message. Use /commit-message [skip-review] to skip the code review.
allowed-tools: Bash(git status:*), Bash(git diff --staged:*), Bash(git commit:*), Bash(git log:*)
argument-help: |
  [skip-review] (optional) — if provided, skip the code review step and go straight to commit message generation.
---

## Invocation

The user may invoke this skill as:
- `/commit-message` — run full flow including code review (default)
- `/commit-message skip-review` — skip code review, go straight to commit message

The `[skip-review]` placeholder is optional. If present, skip Step 1.

## Context

- Current git status: !`git status`
- Current git diff: !`git diff --staged`
- Recent commit history (for context): !`git log --oneline -5`

## Guard clause

If there are no staged changes, stop immediately and tell the user nothing is staged. Do not proceed further.

---

## Step 1 — Code Review

Skip this step entirely if the user passed `skip-review`.

### 1a — Assess scope

Before reviewing, determine the size and nature of the diff:
- **Small** — single responsibility change, < ~50 lines
- **Medium** — multiple related changes, ~50–200 lines
- **Large** — significant feature or refactor, 200+ lines

For **large** diffs, explicitly note at the top of the review: "This is a large diff — consider splitting into smaller commits if changes are logically separable."

### 1b — Detect languages

Identify all languages present in the diff. Apply the relevant checks from section 1d for each detected language simultaneously.

### 1c — Universal checks

Apply these regardless of language:

**Bugs & logic**
- Off-by-one errors, null/undefined/null-ref access, wrong conditions
- Unhandled promise rejections or missing error handling
- Edge cases that could cause runtime errors
- Async/await misuse (missing await, fire-and-forget without intent)

**Code quality**
- Dead code, unused imports, or leftover debug statements (`console.log`, `debugger`, `Console.WriteLine` used for debugging, `print` statements)
- Hardcoded values that should be constants or env vars
- Functions or methods doing too many things (single responsibility)
- Deeply nested logic that could be flattened

**Breaking changes**
- Renamed or removed exported functions, classes, or interfaces
- Changed function signatures or return types
- Removed or renamed API endpoints or database fields
- Any change that could silently break consumers or dependents

**Test coverage**
- New functions, methods, or branches with no accompanying tests
- Existing tests that may no longer cover the changed logic
- Note if no test files are present in the diff for non-trivial logic changes

**Performance**
- N+1 query patterns or missing query batching
- Large allocations or heavy operations inside loops
- Missing pagination on potentially large data sets
- Unnecessary re-renders or recomputations (frontend)

**Dependency changes**
- If `package.json`, `.csproj`, `*.csproj`, `requirements.txt`, `Cargo.toml`, or similar are modified:
  - Flag new dependencies (is this necessary? is it well-maintained?)
  - Flag version bumps (breaking change risk?)
  - Flag removed dependencies (anything still importing it?)

**Security**
- Secrets, tokens, or credentials accidentally staged
- User input used without validation or sanitization
- SQL or command injection risks
- Insecure defaults or disabled security checks

### 1d — Language-specific checks

Apply the relevant section(s) based on detected languages:

**TypeScript / JavaScript**
- `any` types, missing return types, unsafe `as X` assertions
- Missing null checks on optional chaining results
- `useEffect` dependencies array issues (React)
- Unhandled `.catch()` on promises

**C#**
- Nullable reference warnings, missing `null` checks on reference types
- Overuse of `dynamic`, hiding type errors at runtime
- Unhandled exceptions in `async` methods (`async void` outside event handlers)
- `var` used where the inferred type is non-obvious
- LINQ expressions that could throw on empty sequences (`.First()` vs `.FirstOrDefault()`)
- Missing `using` / `IDisposable` patterns for unmanaged resources
- Overly broad `catch (Exception)` without logging or rethrowing

**Other languages**
- Apply equivalent type safety checks and common anti-pattern checks relevant to the detected language

### 1e — Review output format

Use severity levels to make findings actionable:

If issues are found, group them by severity:

> ⛔ **Blockers** — must fix before committing:
> - [issue + file/line if identifiable]
>
> ⚠️ **Warnings** — should fix, or explicitly decide to accept:
> - [issue + file/line if identifiable]
>
> 💡 **Suggestions** — worth considering, but not blocking:
> - [issue + file/line if identifiable]

If nothing noteworthy:
> ✅ **Looks good** — no issues found.

After showing findings, ask the user: **"Do you want to fix any of these before committing, or proceed anyway?"**
Do not proceed to Step 2 until the user responds.

---

## Step 2 — Commit message

Proceed here after the user confirms they want to continue (or immediately if `skip-review` was passed).

Analyze the staged changes and propose a commit message. Use present tense and explain **why** something changed, not just what. Use the recent commit history for context on style and conventions already in use.

### Commit types with emojis

- ✨ `feat:` — New feature
- 🐛 `fix:` — Bug fix
- 🔨 `refactor:` — Refactoring code
- 📝 `docs:` — Documentation
- 🎨 `style:` — Styling/formatting
- ✅ `test:` — Tests
- ⚡ `perf:` — Performance
- 🔒 `security:` — Security fix
- ⬆️ `deps:` — Dependency update
- 🧹 `chore:` — Tooling, config, or other maintenance with no source/behavior change
- 🚨 `breaking:` — Breaking change

### Format

For small changes:
```
<emoji> <type>: <concise_description>
```

For medium/large changes, include a body:
```
<emoji> <type>: <concise_description>

<why this change was needed>

<what approach was taken and why>
```

If breaking changes are present, append a footer instead of describing them in the body:
```
BREAKING CHANGE: <description of what breaks and how to migrate>
```

---

## Output

1. Show summary of staged changes and assessed scope
2. Show review findings with severity levels (Step 1) — unless `skip-review` was passed
3. Wait for user confirmation before proceeding
4. Propose commit message with appropriate emoji and format
5. Ask for confirmation before committing

**DO NOT auto-commit** — wait for user approval. Only commit if the user explicitly confirms.