## 0.0.13 (2025-05-22)

### Added

- Rename `--verbosity` flag into `--log-level`. Keep former as alias (5a88fb, @mbarbin).
- Add a type for message levels and add new `Err.emit t ~level` function (#7, @mbarbin).

### Changed

- Improve rendering of err with context when printing to the console (@mbarbin).
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
