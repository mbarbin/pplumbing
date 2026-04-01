## 0.0.17 (2026-04-01)

### Added

- Added new `Color_mode` module to `pplumbing-pp-tty` with color detection and env var support (#44, @mbarbin).
- Added `Atomic0` stdlib extension for multicore-safe atomic operations (#44, @mbarbin).
- Added `to_dyn` helpers to `Err` interface (#43, @mbarbin).
- Added `Pp_tty.{sexp,dyn}`, `Err.{sexp,dyn}` (#43, @mbarbin).
- Added `Err.reset_loc` and `Err.set_exit_code` (#41, @mbarbin).
- Added new module `Code_error` to `pplumbing-err` (#40, @mbarbin).
- Added new tests, extend coverage (#36, @mbarbin).
- Added new stdlib extension for the tests (#36, @mbarbin).
- Added `dunolint` config and workflow (#31, @mbarbin).

### Changed

- Fix `Err` stderr flushing by routing all output through `Format.err_formatter` (#44, @mbarbin).
- Replace toplevel mutable references by atomics for OCaml 5 multicore correctness (#44, @mbarbin).
- Fix `Log` color rendering by restoring formatter-aware dispatch (#44, @mbarbin).
- Pass resolved color mode to `Fmt_tty` for env var consistency (#44, @mbarbin).
- Revert `Sexp`/`Dyn` styling to no-style by default (#44, @mbarbin).
- Allow more control on color mode with getter based on unix file descriptor (#44, @mbarbin).
- Simplify use of `Err` and `Pp_tty` in tests (#42, @mbarbin).
- Document deprecation of `pplumbing` meta-package.
- Vendor more of stdune `ansi-color` (#39, @mbarbin).
- Reduce overal tests and dev dependencies (#37, @mbarbin).
- Various improvements to the project's CI (#32, @mbarbin).
- Internal improvements to dune files (#31, @mbarbin).
- Simplify dev dependencies (#27, @mbarbin).
- Refactor pkg directory structure (#30, @mbarbin).
- Enabled OCaml `5.4` in CI (#28, @mbarbin).
- Use split pkgs (#26, @mbarbin).

### Deprecated

- Produce `ocaml.deprecated` alerts for api documented as deprecated in `0.0.16`.

## 0.0.16 (2025-09-21)

### Changed

- Split remaining pakages to isolate dependencies (#25, @mbarbin).

## 0.0.15 (2025-09-19)

### Added

- Add a cmdlang runner based on climate for programs using `Err` (#22, @mbarbin).

### Changed

- Improve names `cmdlang-{backend}-err-runner` for cmd runners (#23, @mbarbin).
- Split pakages to isolate dependencies (#18, #19, #20, #21, @mbarbin).

## 0.0.14 (2025-05-26)

### Changed

- Conditional set implicit transitive deps in CI depending on the compiler version (#12, @mbarbin).

## 0.0.13 (2025-05-22)

### Added

- Rename `--verbosity` flag into `--log-level`. Keep former as alias (5a88fb, @mbarbin).
- Add a type for message levels and add new `Err.emit t ~level` function (#7, @mbarbin).

### Changed

- Improve rendering of err with context when printing to the console (#11, @mbarbin).
- Support build with OCaml 4.14 (#10, @mbarbin).
- Increment errors and warning counts even when the message is not shown (#8, @mbarbin).

### Fixed

- Do not print raised errors and exceptions when in quiet mode (#9, @mbarbin).

## 0.0.12 (2025-05-06)

This release prepares the deprecation of a few functions and contains `ocamlmig` annotations to help users with the migration.

To automatically apply the migration changes, first upgrade your `pplumbing` dependency and re-build your project. Then run the command `ocamlmig migrate` from the root of your project.

### Added

- Add concept of error "context" that can be augmented (#6, @mbarbin).
- Better support and rendering of errors built with `Err.sexp` (#6, @mbarbin).

### Changed

- Tweak some details in format of `Err.sexp_of_t` (#6, @mbarbin).
- Do not include exit code in `Err.sexp_of_t` by default (#6, @mbarbin).
- Rename `Err.pp_of_sexp` to `Err.sexp` to make it shorter (#4, @mbarbin).

### Deprecated

- Prepare the deprecation of sexp based err constructors (#4, @mbarbin).

### Removed

- Replaced `Err.append` by `Err.add_context` (#6, @mbarbin).
- Removed `Stdune.User_message.t -> Err.t` helper (#5, @mbarbin).

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
