(lang dune 3.20)

(name pplumbing)

(generate_opam_files)

(license MIT)

(authors "Mathieu Barbin")

(maintainers "Mathieu Barbin <opensource@mbarbin.org>")

(source
 (github mbarbin/pplumbing))

(documentation "https://mbarbin.github.io/pplumbing/")

(using mdx 0.4)

(implicit_transitive_deps false-if-hidden-includes-supported)

(package
 (name pplumbing)
 (synopsis "Utility libraries to use with [pp]")
 (depends
  (ocaml
   (>= 4.14))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (fmt
   (>= 0.9.0))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.7.0))
  (ordering
   (>= 3.17))
  (parsexp
   (>= v0.16))
  (pp
   (>= 2.0.0))
  (sexplib0
   (>= v0.16))
  (stdune
   (>= 3.17))))

(package
 (name pplumbing-tests)
 (synopsis "Tests for pplumbing")
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (>= v0.17))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (expect_test_helpers_core
   (>= v0.17))
  (fmt
   (>= 0.9.0))
  (fpath
   (>= 0.7.3))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.9.0))
  (mdx
   (>= 2.4))
  (ordering
   (>= 3.17))
  (parsexp
   (>= v0.17))
  (pp
   (>= 2.0.0))
  (pplumbing
   (= :version))
  (ppx_compare
   (>= v0.17))
  (ppx_enumerate
   (>= v0.17))
  (ppx_expect
   (>= v0.17))
  (ppx_hash
   (>= v0.17))
  (ppx_here
   (>= v0.17))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)))
  (ppx_let
   (>= v0.17))
  (ppx_sexp_conv
   (>= v0.17))
  (ppx_sexp_value
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (sexplib0
   (>= v0.17))
  (stdio
   (>= v0.17))
  (stdune
   (>= 3.17))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))

(package
 (name pplumbing-dev)
 (synopsis
  "Package to regroup dev targets for the pplumbing project, documentation, and more")
 (allow_empty) ; The package is attached to stanza in doc/ however dune doesn't see it.
 (depends
  (ocaml
   (>= 5.2))
  (ocamlformat
   (and
    :with-dev-setup
    (= 0.27.0)))
  (base
   (>= v0.17))
  (bisect_ppx
   (and
    :with-dev-setup
    (>= 2.8.3)))
  (cmdlang
   (>= 0.0.9))
  (cmdlang-to-cmdliner
   (>= 0.0.9))
  (cmdliner
   (>= 1.3.0))
  (dyn
   (>= 3.17))
  (expect_test_helpers_core
   (>= v0.17))
  (fmt
   (>= 0.9.0))
  (fpath
   (>= 0.7.3))
  (loc
   (>= 0.2.2))
  (logs
   (>= 0.9.0))
  (mdx
   (>= 2.4))
  (ordering
   (>= 3.17))
  (parsexp
   (>= v0.17))
  (pp
   (>= 2.0.0))
  (pplumbing
   (= :version))
  (pplumbing-tests
   (= :version))
  (ppx_compare
   (>= v0.17))
  (ppx_enumerate
   (>= v0.17))
  (ppx_expect
   (>= v0.17))
  (ppx_hash
   (>= v0.17))
  (ppx_here
   (>= v0.17))
  (ppx_js_style
   (and
    :with-dev-setup
    (>= v0.17)))
  (ppx_let
   (>= v0.17))
  (ppx_sexp_conv
   (>= v0.17))
  (ppx_sexp_value
   (>= v0.17))
  (ppxlib
   (>= 0.33))
  (sexplib0
   (>= v0.17))
  (stdio
   (>= v0.17))
  (stdune
   (>= 3.17))
  (sherlodoc
   (and
    :with-doc
    (>= 0.2)))))
