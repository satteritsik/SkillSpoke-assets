# Commit & Reference Style Guide

This repository uses **Conventional Commits** plus explicit **GitHub references**. The goals: readable history, clean
release notes, and predictable automation (auto-closing issues, linking PRs/commits).

## 1) Commit message format

```
<type>(<optional-scope>): <subject in imperative, ≤ 72 chars>

<body: why + what changed + side effects, wrapped at 72 cols>

Refs: #123, satteritsik/SkillSpoke-other#456
Closes: #789
Co-authored-by: Name <email@example.com>
Signed-off-by: Name <email@example.com>
```

- **type**: `feat` | `fix` | `docs` | `refactor` | `perf` | `test` | `build` | `ci` | `chore` | `revert`
- **scope**: optional module/service, e.g., `search`, `ranker`, `api`
- **subject**: imperative mood ("Add", "Fix", "Remove"); no trailing period
- **body**: explain *why*, summarize *what*; note risks/rollbacks

**Breaking changes**

```
BREAKING CHANGE: config schema now requires field X
```

## 2) Referencing issues/PRs/commits

### Auto-close keywords (parsed by GitHub)

Use one of these verbs followed by a reference; closure happens when the commit/PR merges into the **default branch** of
the target repo:

- `fix`, `fixes`, `fixed`
- `close`, `closes`, `closed`
- `resolve`, `resolves`, `resolved`

**Same repo**

```
Fixes #123
Closes #45
Resolves #789
```

**Cross-repo**

```
Fixes satteritsik/SkillSpoke-auth-service#123
```

**Multiple**

```
Fixes #12, closes #34 and resolves satteritsik/SkillSpoke-other#56
```

### "Reference only" (no auto-close)

Use neutral words when you do not want automation:

```
Refs: #123
Related to: satteritsik/SkillSpoke-other#45
See also: #67, satteritsik/SkillSpoke-other@abc1234
```

### Commits, tags, ranges

- Commit: `abc1234` (same repo) or `satteritsik/SkillSpoke-other@abc1234` (cross-repo)
- Tag: `v1.2.3`
- Compare view: `satteritsik/SkillSpoke@v1.2.0...v1.3.0`

### File/line links (paste full URL)

```
https://github.com/satteritsik/SkillSpoke/blob/<SHA>/path/file.ext#L10-L25
```

### Jira references

Configure **Settings → Autolink references** (prefix `SS-` → Jira URL), then use:

```
Refs: SS-123
```

## 3) Best practices

- Put `Fixes #…` in the **PR description** (works best) or in the commit **body** (not subject).
- Keep the subject ≤ 72 chars; wrap the body to 72 columns.
- One logical change per commit; squash noisy WIP commits.
- Use `Co-authored-by:` for pair/mob commits; use `Signed-off-by:` for DCO if required.
- Don't put references inside code blocks—GitHub won't parse them.

## 4) Examples

**Auto-close + reference**

```
fix(search): handle empty provider payloads

Guard against empty responses and retry with jitter; adds metric `provider.empty_payload`.

Fixes #842
Refs: #797
```

**Cross-repo close**

```
feat(api): expose /search/preview endpoint

Adds paginated preview results for UI; rate-limited by tenant.

Closes satteritsik/SkillSpoke-frontend#1123
Refs: satteritsik/SkillSpoke-jobs#88
```

**Related only**

```
refactor(rank): extract hybrid scorer

No functional change; splits scoring weights into separate module.

Refs: #900
```
