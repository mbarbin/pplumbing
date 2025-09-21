<h1 align="center">
  <p align="center">pplumbing</p>
  <img
    src="./doc/static/img/pplumbing.jpg"
    width='216'
    alt="Logo"
  />
</h1>

<p align="center">
  <a href="https://github.com/mbarbin/pplumbing/actions/workflows/ci.yml"><img src="https://github.com/mbarbin/pplumbing/workflows/ci/badge.svg" alt="CI Status"/></a>
  <a href="https://coveralls.io/github/mbarbin/pplumbing?branch=main"><img src="https://coveralls.io/repos/github/mbarbin/pplumbing/badge.svg?branch=main" alt="Coverage Status"/></a>
</p>

*pplumbing* defines a set of utility libraries to use with `pp`. It is compatible with `logs` and inspired by design choices used by *Dune* for user messages. These libraries are meant to combine nicely into a small ecosystem of useful helpers to build CLIs in OCaml.

- `Pp_tty` extends `pp` to build colored documents in the user's terminal using ANSI escape codes.

- `Err` is an abstraction to report located errors and warnings to the user.

- `Log` is an interface to `logs` using `Pp_tty` rather than `Format`.

- `Log_cli` contains functions to work with `Err` on the side of end programs (such as a command line tools). It defines command line helpers to configure the `Err` library, while taking care of setting the `logs` and `fmt` style rendering.

- `Cmdlang_cmdliner_err_runner` is a library for running command line programs specified with `cmdlang` with `cmdliner` as a backend and making opinionated choices, assuming your dependencies are using `Err`.

- `Cmdlang_climate_err_runner` is a library for running command line programs specified with `cmdlang` with `climate` as a backend and making opinionated choices, assuming your dependencies are using `Err`.

## Links to plumbed projects

- [cmdlang](https://github.com/mbarbin/cmdlang)
- [cmdliner](https://github.com/dbuenzli/cmdliner)
- [climate](https://github.com/gridbugs/climate)
- [dune](https://github.com/ocaml/dune)
- [fmt](https://github.com/dbuenzli/fmt)
- [logs](https://github.com/dbuenzli/logs)
- [pp](https://github.com/ocaml-dune/pp)

## Experimental Status

:construction: `pplumbing` is currently under construction. During this initial `0.0.X` experimental phase, the interfaces and behavior are subject to breaking changes.

## Acknowledgements

- We are thankful to the authors and contributors of the projects we use as dependencies.

- We would like to thank the *Dune* developers for the user-facing error handling of Dune (`Stdune.User_message`), on which we based the error handling scheme used in `Err`. By adopting a similar approach, we aim to provide a consistent and unified user experience for OCaml users across different tools and libraries.
