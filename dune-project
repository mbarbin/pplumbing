(lang dune 3.17)

(name pplumbing)

(generate_opam_files)

(license MIT)

(authors "Mathieu Barbin")

(maintainers "Mathieu Barbin <opensource@mbarbin.org>")

(source
 (github mbarbin/pplumbing))

(documentation "https://mbarbin.github.io/pplumbing/")

;; The value for the [implicit_transitive_deps] option is set during the CI
;; depending on the OCaml compiler version.
;;
;; This will be set to [false] iif [ocaml-version >= 5.2].
;;
;; For packaging purposes with older ocaml, it is simpler atm if the option is
;; set to [true] in the main branch.
;;
;; See: [.github/workflows/edit_dune_project_dot_ml].

(implicit_transitive_deps true)

;; This meta-package is deprecated and will not be published to opam for
;; versions > 0.0.16. It is kept here because [dune-release] requires a
;; package whose name matches the project name.

(package
 (name pplumbing)
 (synopsis "Utility libraries to use with [pp]")
 (depends
  (ocaml
   (>= 4.14))
  (cmdlang-cmdliner-err-runner
   (= :version))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (pplumbing-err
   (= :version))
  (pplumbing-log
   (= :version))
  (pplumbing-log-cli
   (= :version))
  (pplumbing-pp-tty
   (= :version))))

(package
 (name pplumbing-pp-tty)
 (synopsis "Build pretty printed documents for the user with [pp]")
 (depends
  (ocaml
   (>= 4.14))
  (dyn
   (>= 3.17))
  (loc
   (>= 0.2.2))
  (pp
   (>= 2.0.0))
  (sexplib0
   (>= v0.16))
  (stdune
   (>= 3.17))))

(package
 (name pplumbing-err)
 (synopsis "Report located errors and warnings to the user with [pp]")
 (depends
  (ocaml
   (>= 4.14))
  (dyn
   (>= 3.17))
  (loc
   (>= 0.2.2))
  (pp
   (>= 2.0.0))
  (pplumbing-pp-tty
   (= :version))
  (sexplib0
   (>= v0.16))
  (stdune
   (>= 3.17))))

(package
 (name pplumbing-log)
 (synopsis "An interface to [logs] using [Pp_tty] rather than [Format]")
 (depends
  (ocaml
   (>= 4.14))
  (logs
   (>= 0.7.0))
  (pp
   (>= 2.0.0))
  (pplumbing-pp-tty
   (= :version))))

(package
 (name pplumbing-log-cli)
 (synopsis
  "Command line helpers to configure the [err], [logs] and [fmt] libraries")
 (depends
  (ocaml
   (>= 4.14))
  (cmdlang
   (>= 0.0.9))
  (fmt
   (>= 0.9.0))
  (logs
   (>= 0.7.0))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (= :version))
  (pplumbing-log
   (= :version))
  (pplumbing-pp-tty
   (= :version))))

(package
 (name cmdlang-cmdliner-err-runner)
 (synopsis "Cmdlang runner for programs using [Err] with a cmdliner backend")
 (depends
  (ocaml
   (>= 4.14))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (pplumbing-err
   (= :version))))

(package
 (name cmdlang-climate-err-runner)
 (synopsis "Cmdlang runner for programs using [Err] with a climate backend")
 (depends
  (ocaml
   (>= 4.14))
  (climate
   (>= 0.8.0))
  (cmdlang
   (>= 0.0.10))
  (cmdlang-to-climate
   (>= 0.0.10))
  (pplumbing-err
   (= :version))))

(package
 (name pplumbing-tests)
 (synopsis "Tests for pplumbing")
 (depends
  (ocaml
   (>= 5.2))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-climate-err-runner
   (= :version))
  (cmdlang-cmdliner-err-runner
   (= :version))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dune-build-info
   (>= 3.17))
  (dyn
   (>= 3.17))
  (fpath
   (>= 0.7.3))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.9.0))
  (ordering
   (>= 3.17))
  (pp
   (>= 2.0.0))
  (pplumbing-err
   (= :version))
  (pplumbing-log
   (= :version))
  (pplumbing-log-cli
   (= :version))
  (pplumbing-pp-tty
   (= :version))
  (ppx_expect
   (>= v0.17))
  (sexplib0
   (>= v0.17))
  (stdune
   (>= 3.17))))

(package
 (name pplumbing-dev)
 (synopsis "Package to regroup dev targets, documentation, and more")
 (allow_empty)
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (= 0.29.0))
  (bisect_ppx
   (>= 2.8.3))
  (cmdlang-climate-err-runner
   (= :version))
  (cmdlang-cmdliner-err-runner
   (= :version))
  (pplumbing-err
   (= :version))
  (pplumbing-log
   (= :version))
  (pplumbing-log-cli
   (= :version))
  (pplumbing-pp-tty
   (= :version))
  (pplumbing-tests
   (= :version))
  (ppx_js_style
   (>= v0.17))
  (sherlodoc
   (>= 0.2))))
