# Release Process

This project uses Semantic Versioning.

- `PATCH` for fixes (`v0.4.1`)
- `MINOR` for backward-compatible features (`v0.5.0`)
- `MAJOR` for breaking changes (`v1.0.0`)

## Pre-release checklist

1. Merge all intended PRs to `main`.
2. Ensure CI is green on `main`.
3. Update `CHANGELOG.md`.
4. Verify README/vimdoc changes are included.
5. Run local smoke checks.

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
4. Tag next patch version.
