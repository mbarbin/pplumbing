## 0.0.12 (unreleased)

### Added

### Changed

- Rename `Err.pp_of_sexp` to `Err.sexp` to make it shorter (#4, @mbarbin).

### Deprecated

- Prepare the deprecation of sexp based err constructors (#4, @mbarbin).

### Fixed

## 0.0.11 (2025-04-25)

### Added

- Add `Err.Color_mode` to access value of cli arg `--color=(auto|always|never)` (#3, @mbarbin).
- Add `Err.Log_level` getters related to current log level (#3, @mbarbin).

### Changed

- Add `Err.Log_level.App` for better compatibility with `Logs` (#3, @mbarbin).

### Deprecated

- In `Log_cli.Config` depreate `logs_level` and `fmt_style_renderer` (#3, @mbarbin).

### Fixed

- Make `Err.error_count` include errors emitted via `Logs.err` - same for warnings (#3, @mbarbin).
- Make `Err.had_errors` include errors emitted via `Logs.err` (#3, @mbarbin).

## 0.0.10 (2025-03-09)

### Fixed

- Fix typo in project name as it was meant to be `pplumbing`.

## 0.0.9 (2025-03-09)

This release is about preparing the publication of the project to the public opam repository.

### Changed

- Rename project `pplumbing`.
- Now publish `cmdlang-cmdliner-runner` as a subpackage.

## 0.0.8 (2024-11-14)

### Changed

- Upgrade to `cmdlang.0.0.8`.

## 0.0.7 (2024-11-10)

Initialize release, continue from release numbers of `cmdlang`.

### Added

- Added packages `pp_tty` and `pp_log`.
- Moved from `cmdlang` the packages `err`, `err-cli` and `cmdlang-cmdliner-runner`.

### Changed

- Renamed `Err_cli` => `Log_cli`.
