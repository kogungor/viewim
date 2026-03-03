# Release Process

This project uses Semantic Versioning.

- `PATCH` for fixes (`v0.4.1`)
- `MINOR` for backward-compatible features (`v0.5.0`)
- `MAJOR` for breaking changes (`v1.0.0`)

## Pre-release checklist

1. Merge all intended feature/fix PRs into `dev`.
2. Ensure CI is green on `dev`.
3. Open release PR: `dev -> main`.
4. Ensure CI is green on `main` for the release PR.
5. Update `CHANGELOG.md`.
6. Verify README/vimdoc changes are included.
7. Run local smoke checks.

## Tag and release

```sh
git checkout main
git pull origin main
git tag vX.Y.Z
git push origin vX.Y.Z
```

Then in GitHub:

1. Open Releases.
2. Create release from `vX.Y.Z`.
3. Paste changelog highlights.
4. Publish.

## Hotfix release

1. Branch from latest release commit: `hotfix/*`.
2. Apply minimal fix.
3. PR to `main`.
4. After merge, cherry-pick or port hotfix to `dev`.
5. Tag next patch version.
