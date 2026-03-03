# Changelog

All notable changes to this project are documented here.

## [Unreleased]

### Added

- Process docs: `CONTRIBUTING.md`, `RELEASE.md`, and GitHub templates.
- `:SearchImage [query]` MVP command with project image discovery and builtin selector flow.
- Search picker adapter layer with `search.preferred_picker` (`telescope`, `snacks`, `builtin`, `auto`) and fallback resolution.

### Changed

- Development/release process docs now use `dev` as integration branch and `main` as release branch.
- CI now runs on `dev` and `main` for both push and pull request events.
