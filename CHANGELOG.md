# Changelog

## [0.3.1] - 2026-09-13
### Fixed
- Ships `lib/radfish-supermicro.rb`, so `require "radfish-supermicro"` works.
  Without it that raised LoadError, and because radfish auto-loads adapters
  with `require "radfish-supermicro"` inside a `rescue LoadError`, the adapter
  silently never registered: `Radfish.supported_vendors` omitted supermicro
  after a plain `require "radfish"`. `Radfish::Client` still worked, because it
  falls back to `require "radfish/<vendor>_adapter"`, which masked this.
  The other two adapter gems already had their entry point.

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
