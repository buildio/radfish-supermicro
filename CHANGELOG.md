# Changelog

## [0.3.0] - 2026-09-11
### Changed
- **Breaking:** `set_boot_override` and the `boot_to_*` helpers take
  `persistence:` instead of `enabled:`. (#1, thanks @davispuh)
- Requires supermicro >= 0.2.0 and radfish >= 0.3.0, which is where the
  matching `persistence:` signatures live. An older client gem can no longer
  resolve against this adapter.

### Added
- CI on push and pull request, and a release workflow publishing to RubyGems
  through trusted publishing (OIDC).
