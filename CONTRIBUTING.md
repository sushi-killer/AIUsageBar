# Contributing to AI Usage Bar

## Prerequisites

- macOS 13.0+
- Xcode 15+ (Swift 5.9)
- Claude Code CLI and/or Codex CLI (for testing)

## Branch naming

All work happens in short-lived branches off `main`. Name format:

```
<type>/<short-description>
```

| Type | When to use | Example |
|------|------------|---------|
| `feature/` | New functionality | `feature/codex-token-display` |
| `fix/` | Bug fix | `fix/keychain-cache-race` |
| `refactor/` | Code cleanup | `refactor/extract-usage-parser` |
| `docs/` | Documentation only | `docs/contributing-branching` |
| `test/` | Adding or fixing tests | `test/notification-edge-cases` |
| `chore/` | Build, CI, config, dependencies | `chore/xcode-15-settings` |
| `release/` | Release prep (maintainer only) | `release/v1.0.0` |

Rules:
- Lowercase, kebab-case: `fix/panel-position-bug` (not `Fix/Panel_Position`)
- Max 4 words in description — enough to understand, short enough for `git log`
- No issue number in branch name (put it in commit messages and PR description)
- One concern per branch — don't mix a feature with an unrelated refactor

## Workflow

```
main (protected)
 └── feature/my-feature   ← your work here
      ├── commit 1
      ├── commit 2
      └── PR → main
```

1. **Create branch** from latest `main`:
   ```bash
   git checkout main && git pull
   git checkout -b feature/my-feature
   ```
2. **Work** — commit often, with clear messages (see below).
3. **Tests pass** before pushing:
   ```bash
   xcodebuild test -scheme AIUsageBar -destination 'platform=macOS'
   ```
4. **Push and open PR** to `main`.
5. **Code review** — at least one approval required.
6. **Merge** — squash merge preferred (keeps `main` history clean).
7. **Delete branch** after merge.

## Commit messages

Format:
```
<type>: <what changed>
```

Examples:
```
feature: add Codex token usage display
fix: prevent duplicate file watcher observers
refactor: extract credential parsing from KeychainService
test: add threshold notification edge cases
docs: document branch naming conventions
chore: update deployment target to macOS 13.5
```

- Imperative mood: "add", not "added" or "adds"
- No period at the end
- First line under 72 characters
- Body (optional) separated by blank line — explain **why**, not **what**

## What goes where

```
AIUsageBar/
├── Models/          ← data types, enums (Provider, UsageData, Settings)
├── Services/        ← singletons, actors, system integrations
├── Views/           ← SwiftUI views only
└── AIUsageBarApp.swift

AIUsageBarTests/     ← mirrors source structure, one test file per source file
docs/                ← documentation, screenshots
install.sh           ← user install script
release.sh           ← maintainer release script
```

- New view → `Views/`
- New provider or system service → `Services/`
- New data model → `Models/`
- Test for `Foo.swift` → `FooTests.swift`

## Guidelines

- **Swift only** — no external dependencies
- **macOS 13+ API only** — no `@Observable`, SwiftData, or other macOS 14+ APIs
- PR description should explain **what** changed and **why**
- Keep changes focused — one feature or fix per PR
- Don't push directly to `main` — always use a PR
- Run tests before opening a PR:
  `xcodebuild test -scheme AIUsageBar -destination 'platform=macOS'`

## Code style

- Follow existing patterns in the codebase
- Use `ObservableObject` + `@Published` for state
- Prefer `actor` for thread-safe types (see `ClaudeProvider`)
- Static `DateFormatter` instances on types, not per-call
- Views: SwiftUI with AppKit integration where needed (NSPanel, NSStatusItem)

## Reporting issues

Open an issue with:
- macOS version
- Steps to reproduce
- Expected vs actual behavior
